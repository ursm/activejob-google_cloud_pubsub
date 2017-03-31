module ActiveJob
  module GoogleCloudPubsub
    module Naming
      def topic_name(queue_name)
        "activejob-queue-#{queue_name}"
      end

      def subscription_name(queue_name)
        "activejob-worker-#{queue_name}"
      end
    end
  end
end
