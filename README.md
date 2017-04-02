# ActiveJob::GoogleCloudPubsub

[![Build Status](https://travis-ci.org/ursm/activejob-google_cloud_pubsub.svg?branch=master)](https://travis-ci.org/ursm/activejob-google_cloud_pubsub)
[![Gem Version](https://badge.fury.io/rb/activejob-google_cloud_pubsub.svg)](https://badge.fury.io/rb/activejob-google_cloud_pubsub)

Google Cloud Pub/Sub adapter and worker for ActiveJob

## Installation

```ruby
gem 'activejob-google_cloud_pubsub'
```

## Usage

First, change the ActiveJob backend.

``` ruby
Rails.application.config.active_job.queue_adapter = :google_cloud_pubsub
```

Write the Job class and code to use it.

``` ruby
class HelloJob < ApplicationJob
  def perform(name)
    puts "hello, #{name}!"
  end
end
```

``` ruby
class HelloController < ApplicationController
  def say
    HelloJob.perform_later params[:name]
  end
end
```

In order to test the worker in your local environment, it is a good idea to use the Pub/Sub emulator provided by `gcloud` command. Refer to [this document](https://cloud.google.com/pubsub/docs/emulator) for the installation procedure.

When the installation is completed, execute the following command to start up the worker.

``` sh
$ gcloud beta emulators pubsub start

(Switch to another terminal)

$ eval `gcloud beta emulators pubsub env-init`
$ cd path/to/your-app
$ bundle exec activejob-google_cloud_pubsub-worker
```

If you hit the previous action, the job will be executed.
(Both the emulator and the worker stop with <kbd>Ctrl+C</kbd>)

## Configuration

### Adapter

When passing options to the adapter, you need to create the object instead of a symbol.

``` ruby
Rails.application.config.active_job.queue_adapter = ActiveJob::GoogleCloudPubsub::Adapter.new(
  async:  false,
  logger: Rails.logger,

  pubsub: Google::Cloud::Pubsub.new(
    project: 'MY-PROJECT-ID',
    keyfile: 'path/to/keyfile.json'
  )
)
```

#### `async`

Whether to publish messages asynchronously.

Default: `true`

#### `logger`

The logger that outputs a message publishing error. Specify `nil` to disable logging.

Default: `Logger.new($stdout)`

#### `pubsub`

The instance of `Google::Cloud::Pubsub::Project`. Please see [`Google::Cloud::Pubsub.new`](http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-pubsub/master/google/cloud/pubsub?method=new-class) for details.

Default: `Google::Cloud::Pubsub.new`

### Worker

The following command line flags can be specified. All flags are optional.

#### `--require=PATH`

The path of the file to load before the worker starts up.

Default: `./config/environment`

#### `--queue=NAME`

The name of the queue the worker handles.

Note: One worker can handle only one queue. If you use multiple queues, you need to launch multiple worker processes.

Default: `default`

#### `--min_threads=N`

Minimum number of worker threads.

Default: `0`

#### `--max_threads=N`

Maximum number of worker threads.

Default: number of logical cores

#### `--project=PROJECT_ID`, `--keyfile=PATH`

Credentials of Google Cloud Platform. Please see [the document](https://github.com/GoogleCloudPlatform/google-cloud-ruby/blob/master/AUTHENTICATION.md) for details.

## Development

``` sh
$ bundle exec rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ursm/activejob-google_cloud_pubsub.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
