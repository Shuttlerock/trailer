# frozen_string_literal: true

require 'active_support/inflector'
require 'trailer/storage/cloud_watch'

module Trailer::Storage
  # Instantiates the storage backend with the given name, and gives it the trace ID.
  def self.factory(name, trace_id)
    klass = ActiveSupport::Inflector.classify("trailer/storage/#{name}")
    ActiveSupport::Inflector.constantize(klass).new(trace_id)
  end
end
