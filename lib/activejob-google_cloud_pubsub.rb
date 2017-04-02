require 'active_job'
require 'google/cloud/pubsub'

module ActiveJob
  module GoogleCloudPubsub
    autoload :VERSION, 'active_job/google_cloud_pubsub/version'
    autoload :Worker,  'active_job/google_cloud_pubsub/worker'
  end

  module QueueAdapters
    autoload :GoogleCloudPubsubAdapter, 'active_job/google_cloud_pubsub/adapter'
  end
end
