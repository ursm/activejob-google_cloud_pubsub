require 'spec_helper'

require 'active_job'
require 'json'
require 'thread'
require 'timeout'

RSpec.describe ActiveJob::GoogleCloudPubsub, :emulator do
  class GreetingJob < ActiveJob::Base
    def perform(name)
      $queue.push "hello, #{name}!"
    end
  end

  around :all do |example|
    orig, ActiveJob::Base.logger = ActiveJob::Base.logger, nil

    begin
      example.run
    ensure
      ActiveJob::Base.logger = orig
    end
  end

  around :each do |example|
    $queue = Thread::Queue.new

    ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::GoogleCloudPubsubAdapter.new(emulator_host: @emulator_host)

    run_worker emulator_host: @emulator_host, &example
  end

  example do
    GreetingJob.perform_later 'alice'
    GreetingJob.set(wait: 0.1).perform_later 'bob'
    GreetingJob.set(wait_until: Time.now + 0.2).perform_later 'charlie'

    Timeout.timeout 1 do
      expect(3.times.map { $queue.pop }).to contain_exactly(
        'hello, alice!',
        'hello, bob!',
        'hello, charlie!'
      )
    end
  end

  private

  def run_worker(**args, &block)
    worker = ActiveJob::GoogleCloudPubsub::Worker.new(**args)

    worker.ensure_subscription

    thread = Thread.new {
      worker.run
    }

    thread.abort_on_exception = true

    block.call
  ensure
    thread.kill if thread
  end
end
