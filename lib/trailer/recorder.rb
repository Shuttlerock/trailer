# frozen_string_literal: true

module Trailer
  class Recorder
    # Constructor.
    #
    # @param storage [Object] A storage instance. See https://github.com/Shuttlerock/trailer#storage
    def initialize(storage)
      @storage = storage
    end

    # Records the exception class and message on the current trace.
    #
    # @param err [Exception] The exception to record.
    def add_exception(err)
      write(tags.merge(exception: err.class.name, message: err.message, trace: Array(err.backtrace)[0..9]))
    end

    # Finish tracing, and flush storage.
    def finish
      storage.async.flush
      @trace_id = nil
      @tags     = {}
    end

    # Create a new trace ID to link log entries.
    def start
      raise Trailer::Error, 'finish() must be called before a new trace can be started' unless @trace_id.nil?

      # See https://github.com/aws/aws-xray-sdk-ruby/blob/1869ca5/lib/aws-xray-sdk/model/segment.rb#L26-L30
      @trace_id = %(1-#{Time.now.to_i.to_s(16)}-#{SecureRandom.hex(12)})
      @tags     = {} # This is used to accumulate tags in case we have an exception.
    end

    # Write the given hash to storage.
    #
    # @param data [Hash] A key-value hash of trace data to write to storage.
    def write(data)
      raise Trailer::Error, 'start() must be called before write()' if @trace_id.nil?
      raise Trailer::Error, 'data must be an instance of Hash' unless data.is_a?(Hash)

      # Include some standard tags.
      data[:environment]  ||= Trailer.config.environment
      data[:host_name]    ||= Trailer.config.host_name
      data[:service_name] ||= Trailer.config.service_name
      data                  = data.compact.merge(trace_id: trace_id)

      storage.async.write(data)
      @tags.merge!(data)
    end

    private

    attr_accessor :storage, :tags, :trace_id
  end
end
