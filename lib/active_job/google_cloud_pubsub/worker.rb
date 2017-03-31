require 'active_job/base'
require 'active_job/google_cloud_pubsub/naming'
require 'active_support/core_ext/numeric/time'
require 'concurrent'
require 'google/cloud/pubsub'
require 'json'
require 'logger'

module ActiveJob
  module GoogleCloudPubsub
    class Worker
      include Naming

      MAX_DEADLINE = 10.minutes

      cattr_accessor(:logger) { Logger.new($stdout) }

      def initialize(queue: 'default', min_threads: 0, max_threads: Concurrent.processor_count, **pubsub_args)
        @queue_name, @min_threads, @max_threads = queue, min_threads, max_threads

        @pubsub = Google::Cloud::Pubsub.new(**pubsub_args)
      end

      def subscription
        topic = @pubsub.topic(topic_name(@queue_name), autocreate: true)

        topic.subscription(subscription_name(@queue_name)) || topic.subscribe(subscription_name(@queue_name))
      end
      alias ensure_subscription subscription

      def run
        pool = Concurrent::ThreadPoolExecutor.new(min_threads: @min_threads, max_threads: @max_threads, max_queue: -1)

        subscription.listen do |message|
          begin
            Concurrent::Promise.execute(args: message, executor: pool) {|msg|
              process msg
            }.rescue {|e|
              logger.error e
            }
          rescue Concurrent::RejectedExecutionError
            message.delay! 10.seconds.to_i
          end
        end
      end

      private

      def process(message)
        if timestamp = message.attributes['timestamp']
          ts = Time.at(timestamp.to_f)

          if ts >= Time.now
            _process message
          else
            message.delay! [ts - Time.now, MAX_DEADLINE.to_i].min
          end
        else
          _process message
        end
      end

      def _process(message)
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
          else
            # terminated from outside
            message.delay! 0
          end
        end
      end
    end
  end
end
