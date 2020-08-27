# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'
require 'concurrent'

module Trailer
  module Storage
    class CloudWatch
      include Concurrent::Async

      # Constructor.
      def initialize
        self.messages = []
        self.client   = Aws::CloudWatchLogs::Client.new(region: Trailer.config.aws_region, credentials: credentials)
        ensure_log_group
        ensure_log_stream
      end

      # Queues the given hash for writing to CloudWatch.
      #
      # @param data [Hash] A key-value hash of trace data to write to storage.
      def write(data)
        messages << {
          timestamp: (Time.now.utc.to_f.round(3) * 1000).to_i,
          message:   data&.to_json,
        }.compact
      end

      # Sends all of the queued messages to CloudWatch, and resets the messages queue.
      #
      # See https://stackoverflow.com/a/36901509
      def flush
        return if messages.empty?

        events = {
          log_group_name:  Trailer.config.application_name,
          log_stream_name: Trailer.config.application_name,
          log_events:      messages,
          sequence_token:  sequence_token,
        }

        response            = client.put_log_events(events)
        self.sequence_token = response&.next_sequence_token
        self.messages       = []
      rescue Aws::CloudWatchLogs::Errors::InvalidSequenceTokenException
        # Only one client at a time can write to the log. If another client has written before we get a chance,
        # the sequence token is invalidated, and we need to get a new one.
        self.sequence_token = log_stream[:upload_sequence_token]
        retry
      end

      private

      attr_accessor :client, :messages, :sequence_token

      # Returns an AWS credentials instance for writing to CloudWatch.
      def credentials
        Aws::Credentials.new(Trailer.config.aws_access_key_id, Trailer.config.aws_secret_access_key)
      end

      # Creates the log group, if it doesn't already exist. Ideally we would paginate here in case
      # the account has a lot of log groups with the same prefix, but it seems unlikely to happen.
      def ensure_log_group
        existing = client.describe_log_groups.log_groups.find do |group|
          group.log_group_name == Trailer.config.application_name
        end

        client.create_log_group(log_group_name: Trailer.config.application_name) unless existing
      rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
        # No need to do anything - probably caused by lack of pagination.
      end

      # Create the log stream, if it doesn't already exist.
      # Ideally we would paginate here in case the account has a lot of log streams.
      def ensure_log_stream
        if (existing = log_stream)
          self.sequence_token = existing.upload_sequence_token
        else
          client.create_log_stream(
            log_group_name:  Trailer.config.application_name,
            log_stream_name: Trailer.config.application_name,
          )
        end
      rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
        # No need to do anything - probably caused by lack of pagination.
      end

      # Returns the current log stream, if one exists.
      def log_stream
        client.describe_log_streams(
          log_group_name:         Trailer.config.application_name,
          log_stream_name_prefix: Trailer.config.application_name,
        ).log_streams.find do |stream|
          stream.log_stream_name == Trailer.config.application_name
        end
      end
    end
  end
end
