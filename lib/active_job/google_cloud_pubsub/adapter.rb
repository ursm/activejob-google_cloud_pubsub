require 'active_job/google_cloud_pubsub/naming'
require 'google/cloud/pubsub'
require 'json'

module ActiveJob
  module GoogleCloudPubsub
    class Adapter
      include Naming

      def initialize(**pubsub_args)
        @pubsub = Google::Cloud::Pubsub.new(pubsub_args)
      end

      def enqueue(job, attributes = {})
        topic = @pubsub.topic(topic_name(job.queue_name), autocreate: true)

        topic.publish JSON.dump(job.serialize), attributes
      end

      def enqueue_at(job, timestamp)
        enqueue job, timestamp: timestamp
      end
    end
  end
end

require 'active_job'

ActiveJob::QueueAdapters::GoogleCloudPubsubAdapter = ActiveJob::GoogleCloudPubsub::Adapter
