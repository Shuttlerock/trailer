# frozen_string_literal: true

class ShuttlerockTracer::Configuration
  # The default destination to push traces to.
  DEFAULT_DESTINATION = :cloud_watch

  attr_accessor :aws_access_key_id,
                :aws_secret_access_key,
                :aws_region,
                :destination

  def initialize
    @aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
    @aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    @aws_region            = ENV.fetch('AWS_REGION', 'us-east-1')
    @destination           = DEFAULT_DESTINATION
  end
end
