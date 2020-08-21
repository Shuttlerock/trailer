# frozen_string_literal: true

require 'trailer/storage'

class Trailer::Recorder
  # Finish tracing, and write to storage.
  def finish
    storage.flush
  end

  # Write the given hash to storage.
  def write(data)
    storage.write(data)
  end

  # Create a new trace ID, and instantiate the storage instance.
  def start
    # See https://github.com/aws/aws-xray-sdk-ruby/blob/1869ca5/lib/aws-xray-sdk/model/segment.rb#L26-L30
    trace_id = %(1-#{Time.now.to_i.to_s(16)}-#{SecureRandom.hex(12)})
    @storage = Trailer::Storage.factory(Trailer.config.storage, trace_id)
  end

  private

  attr_accessor :storage
end
