require 'active_job/google_cloud_pubsub/pubsub_extension'
require 'google/cloud/pubsub'
require 'json'

module ActiveJob
  module GoogleCloudPubsub
    class Adapter
      using PubsubExtension

      def initialize(**pubsub_args)
        @pubsub = Google::Cloud::Pubsub.new(pubsub_args)
      end

      def enqueue(job, attributes = {})
        @pubsub.topic_for(job.queue_name).publish JSON.dump(job.serialize), attributes
      end

      def enqueue_at(job, timestamp)
        enqueue job, timestamp: timestamp
      end
    end
  end
end

require 'active_job'

ActiveJob::QueueAdapters::GoogleCloudPubsubAdapter = ActiveJob::GoogleCloudPubsub::Adapter
