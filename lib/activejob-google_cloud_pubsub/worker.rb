require 'active_job/base'
require 'active_support/core_ext/numeric/time'
require 'activejob-google_cloud_pubsub/pubsub_extension'
require 'concurrent'
require 'google/cloud/pubsub'
require 'json'
require 'logger'

module ActiveJob
  module GoogleCloudPubsub
    class Worker
      MAX_DEADLINE = 10.minutes

      using PubsubExtension

      def initialize(queue: 'default', min_threads: 0, max_threads: Concurrent.processor_count, pubsub: Google::Cloud::Pubsub.new, logger: Logger.new($stdout))
        @queue_name  = queue
        @min_threads = min_threads
        @max_threads = max_threads
        @pubsub      = pubsub
        @logger      = logger
      end

      def run
        pool = Concurrent::ThreadPoolExecutor.new(min_threads: @min_threads, max_threads: @max_threads, max_queue: -1)

        @pubsub.subscription_for(@queue_name).listen {|message|
          @logger&.info "Message(#{message.message_id}) was received."

          begin
            Concurrent::Promise.execute(args: message, executor: pool) {|msg|
              process_or_delay msg
            }.rescue {|e|
              @logger&.error e
            }
          rescue Concurrent::RejectedExecutionError
            Concurrent::Promise.execute(args: message) {|msg|
              msg.delay! 10.seconds.to_i

              @logger&.info "Message(#{msg.message_id}) was rescheduled after 10 seconds because the thread pool is full."
            }.rescue {|e|
              @logger&.error e
            }
          end
        }.start

        sleep
      end

      def ensure_subscription
        @pubsub.subscription_for @queue_name

        nil
      end

      private

      def process_or_delay(message)
        if message.time_to_process?
          process message
        else
          deadline = [message.remaining_time_to_schedule, MAX_DEADLINE.to_i].min

          message.delay! deadline

          @logger&.info "Message(#{message.message_id}) was scheduled at #{message.scheduled_at} so it was rescheduled after #{deadline} seconds."
        end
      end

      def process(message)
        timer_opts = {
          execution_interval: MAX_DEADLINE - 10.seconds,
          timeout_interval:   5.seconds,
          run_now:            true
        }

        delay_timer = Concurrent::TimerTask.execute(timer_opts) {
          message.delay! MAX_DEADLINE.to_i
        }

        begin
          succeeded = false
          failed    = false

          ActiveJob::Base.execute JSON.parse(message.data)

          succeeded = true
        rescue Exception
          failed = true

          raise
        ensure
          delay_timer.shutdown

          if succeeded || failed
            message.acknowledge!

            @logger&.info "Message(#{message.message_id}) was acknowledged."
          else
            # terminated from outside
            message.delay! 0
          end
        end
      end
    end
  end
end
