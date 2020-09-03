# frozen_string_literal: true

module Trailer
  module Storage
    class Null
      include Concurrent::Async

      # Pretends to queue the given hash for writing.
      #
      # @param data [Hash] A key-value hash of trace data to write to storage.
      def write(_data); end

      # Pretends to flush the queued messages to the storage provider.
      def flush; end
    end
  end
end
