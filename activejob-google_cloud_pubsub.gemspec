lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activejob-google_cloud_pubsub/version'

Gem::Specification.new do |spec|
  spec.name          = 'activejob-google_cloud_pubsub'
  spec.version       = ActiveJob::GoogleCloudPubsub::VERSION
  spec.authors       = ['Keita Urashima']
  spec.email         = ['ursm@ursm.jp']

  spec.summary       = 'Google Cloud Pub/Sub adapter and worker for ActiveJob'
  spec.homepage      = 'https://github.com/ursm/activejob-google_cloud_pubsub'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activejob'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'concurrent-ruby'
  spec.add_runtime_dependency 'google-cloud-pubsub', '~> 0.26.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
