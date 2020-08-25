# frozen_string_literal: true

class Trailer::Recorder
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
    write({ exception: err.class.name, message: err.message, trace: err.backtrace[0..9] })
  end

  # Finish tracing, and flush storage.
  def finish
    storage.async.flush
    @trace_id = nil
  end

  # Create a new trace ID to link log entries.
  def start
    raise Trailer::Error, 'finish() must be called before a new trace can be started' unless @trace_id.nil?

    # See https://github.com/aws/aws-xray-sdk-ruby/blob/1869ca5/lib/aws-xray-sdk/model/segment.rb#L26-L30
    @trace_id = %(1-#{Time.now.to_i.to_s(16)}-#{SecureRandom.hex(12)})
  end

  # Write the given hash to storage.
  #
  # @param data [Hash] A key-value hash of trace data to write to storage.
  def write(data)
    raise Trailer::Error, 'start() must be called before write()' if @trace_id.nil?

    storage.async.write(data.merge(trace_id: trace_id))
  end

  private

  attr_accessor :storage, :trace_id
end
