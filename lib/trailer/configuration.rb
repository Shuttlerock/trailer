# frozen_string_literal: true

class Trailer::Configuration
  # The default storage backend to push traces to.
  DEFAULT_STORAGE = :cloud_watch

  attr_accessor :application_name,
                :aws_access_key_id,
                :aws_region,
                :aws_secret_access_key,
                :storage,
                :host_name,
                :service_name

  # Constructor.
  def initialize
    @application_name      = ENV['TRACER_APPLICATION_NAME']
    @aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
    @aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    @aws_region            = ENV.fetch('AWS_REGION', 'us-east-1')
    @storage               = DEFAULT_STORAGE
    @host_name             = ENV['TRACER_HOST_NAME']
    @service_name          = ENV['TRACER_SERVICE_NAME']
  end
end
