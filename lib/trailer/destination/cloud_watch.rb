# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'

module Trailer::Destination
  class CloudWatch
    # Constructor.
    def initialize
      @messages = []
      connect!
    end

    # Queues the given hash for writing to CloudWatch.
    def write(data)
      data[:host_name] = Trailer.config.host_name
      data[:service_name] = Trailer.config.service_name
      @messages << {
        timestamp: (Time.now.utc.to_f.round(3) * 1000).to_i,
        message:   data.merge(host_name: Trailer.config.host_name).to_json,
      }
    end

    # Sends all of the queued messages to CloudWatch, and resets the messages queue.
    def flush
      events = {
        log_group_name:  Trailer.config.application_name,
        log_stream_name: Trailer.config.application_name,
        log_events:      messages,
        sequence_token:  sequence_token,
      }
      response = client.put_log_events(events)
      @sequence_token = response&.next_sequence_token
      @messages       = []
    end

    private

    attr_accessor :client, :messages, :sequence_token

    # Create the log group, if it doesn't already exist.
    # Ideally we would paginate here in case the account has a lot of log groups.
    def create_log_group
      existing = client.describe_log_groups.log_groups.find do |group|
        group.log_group_name == Trailer.config.application_name
      end

      client.create_log_group(log_group_name: Trailer.config.application_name) unless existing
    rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
      # No need to do anything - probably caused by lack of pagination.
    end

    # Create the log stream, if it doesn't already exist.
    # Ideally we would paginate here in case the account has a lot of log streams.
    def create_log_stream
      existing = client.describe_log_streams(log_group_name: Trailer.config.application_name).log_streams.find do |stream|
        stream.log_stream_name == Trailer.config.application_name
      end

      unless existing
        client.create_log_stream(
          log_group_name:  Trailer.config.application_name,
          log_stream_name: Trailer.config.application_name,
        )
      end
    rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
      # No need to do anything - probably caused by lack of pagination.
    end

    # Instantiates a CloudWatch client, and makes sure we have a group and stream to log to.
    def connect!
      @client = Aws::CloudWatchLogs::Client.new(region: Trailer.config.aws_region, credentials: credentials)
      create_log_group
      create_log_stream
    end

    # Returns AWS credentials for writing to CloudWatch.
    def credentials
      Aws::Credentials.new(Trailer.config.aws_access_key_id, Trailer.config.aws_secret_access_key)
    end
  end
end
