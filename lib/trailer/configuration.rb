# frozen_string_literal: true

require 'trailer/storage'

class Trailer::Configuration
  attr_accessor :application_name,
                :aws_access_key_id,
                :aws_region,
                :aws_secret_access_key,
                :storage,
                :host_name,
                :service_name

  # Constructor.
  def initialize
    @application_name      = ENV['TRAILER_APPLICATION_NAME']
    @aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
    @aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    @aws_region            = ENV.fetch('AWS_REGION', 'us-east-1')
    @storage               = Trailer::Storage::DEFAULT
    @host_name             = ENV['TRAILER_HOST_NAME']
    @service_name          = ENV['TRAILER_SERVICE_NAME']
  end
end
