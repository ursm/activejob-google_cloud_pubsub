require 'google/cloud/pubsub'

module ActiveJob
  module GoogleCloudPubsub
    module PubsubExtension
      refine Google::Cloud::Pubsub::Project do
        def topic_for(queue_name)
          name = "activejob-queue-#{queue_name}"

          topic(name) || create_topic(name)
        end

        def subscription_for(queue_name)
          name = "activejob-worker-#{queue_name}"

          subscription(name) || topic_for(queue_name).subscribe(name)
        end
      end
    end
  end
end
