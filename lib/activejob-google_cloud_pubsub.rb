module ActiveJob
  module GoogleCloudPubsub
    autoload :Adapter, 'activejob-google_cloud_pubsub/adapter'
    autoload :VERSION, 'activejob-google_cloud_pubsub/version'
    autoload :Worker,  'activejob-google_cloud_pubsub/worker'
  end
end

require 'active_job'
require 'google/cloud/pubsub'

ActiveJob::QueueAdapters.autoload :GoogleCloudPubsubAdapter, 'activejob-google_cloud_pubsub/adapter'
