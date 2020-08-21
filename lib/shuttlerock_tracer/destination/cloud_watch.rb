# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'

module ShuttlerockTracer::Destination
  class CloudWatch
    def initialize; end

    def write(data); end

    def flush; end

    private

    attr_accessor :client

    # Returns AWS credentials for writing to CloudWatch logs.
    def credentials
      Aws::Credentials.new(ShuttlerockTracer.config.aws_access_key_id, ShuttlerockTracer.config.aws_secret_access_key)
    end
  end
end
