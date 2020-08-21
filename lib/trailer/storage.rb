# frozen_string_literal: true

require 'trailer/storage/cloud_watch'

module Trailer::Storage
  # The default storage backend to push traces to.
  DEFAULT = Trailer::Storage::CloudWatch::NAME

  # Instantiates the storage backend with the given name, and gives it the trace ID.
  def self.factory(name)
    klass = case name.to_s
            when Trailer::Storage::CloudWatch::NAME
              Trailer::Storage::CloudWatch
            else
              raise Trailer::Error, "Unknown storage backend (#{name})"
            end

    klass.new
  end
end
