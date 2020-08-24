# frozen_string_literal: true

require 'trailer/storage/cloud_watch'

class Trailer::Configuration
  attr_accessor :application_name,
                :auto_tag_fields,
                :aws_access_key_id,
                :aws_region,
                :aws_secret_access_key,
                :enabled,
                :storage,
                :host_name,
                :service_name,
                :tag_fields

  # Constructor.
  def initialize
    # The global application or company name.
    @application_name      = ENV['TRAILER_APPLICATION_NAME']
    # When tracing ActiveRecord instances, we can tag our trace with fields matching this regex.
    @auto_tag_fields       = /(_id|_at)$/.freeze
    # AWS access key with CloudWatch write permission.
    @aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
    # The AWS region to log to.
    @aws_region            = ENV.fetch('AWS_REGION', 'us-east-1')
    # The AWS secret.
    @aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    # Allows tracing to be explicitly disabled.
    @enabled               = true
    # Optional - the name of the individual host or server within the service.
    @host_name             = ENV['TRAILER_HOST_NAME']
    # The name of the service within the application.
    @service_name          = ENV['TRAILER_SERVICE_NAME']
    # The storage backend class to use.
    @storage               = Trailer::Storage::CloudWatch
    # Optional - When tracing ActiveRecord instances, we can tag our trace with these fields explicitly.
    @tag_fields            = %w[name]
  end
end
