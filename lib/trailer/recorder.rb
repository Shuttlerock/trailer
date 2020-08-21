# frozen_string_literal: true

class Trailer::Recorder
  # Constructor.
  def initialize(storage)
    @storage = storage
  end

  # Finish tracing, and flush storage.
  def finish
    storage.flush
    @trace_id = nil
  end

  # Create a new trace ID to link log entries.
  def start
    # See https://github.com/aws/aws-xray-sdk-ruby/blob/1869ca5/lib/aws-xray-sdk/model/segment.rb#L26-L30
    @trace_id = %(1-#{Time.now.to_i.to_s(16)}-#{SecureRandom.hex(12)})
  end

  # Write the given hash to storage.
  def write(data)
    raise Trailer::Error, 'start() must be called before write()' if @trace_id.nil?

    storage.write(data.merge(trace_id: trace_id))
  end

  private

  attr_accessor :storage, :trace_id
end
