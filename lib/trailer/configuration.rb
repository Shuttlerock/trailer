# frozen_string_literal: true

require 'trailer/storage/cloud_watch'

module Trailer
  class Configuration
    attr_accessor :application_name,
                  :auto_tag_fields,
                  :aws_access_key_id,
                  :aws_region,
                  :aws_secret_access_key,
                  :current_user_method,
                  :enabled,
                  :environment,
                  :storage,
                  :host_name,
                  :service_name

    attr_reader :tag_fields

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
      # The environment that the application is running (eg. 'production', 'test').
      @environment           = ENV['TRAILER_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']
      # Optional - the name of the individual host or server within the service.
      @host_name             = ENV['TRAILER_HOST_NAME']
      # The name of the service within the application.
      @service_name          = ENV['TRAILER_SERVICE_NAME']
      # The storage backend class to use.
      @storage               = Trailer::Storage::CloudWatch
      # Optional - When tracing ActiveRecord instances, we can tag our trace with these fields explicitly.
      @tag_fields            = %i[name]
    end

    # Make sure we store tag_fields as symbols for consistency.
    def tag_fields=(fields)
      @tag_fields = Array(fields).flatten.map(&:to_sym)
    end
  end
end
