# frozen_string_literal: true

require 'trailer/configuration'
require 'trailer/middleware/rack'
require 'trailer/railtie' if defined?(Rails::Railtie)
require 'trailer/recorder'
require 'trailer/storage'
require 'trailer/version'

module Trailer
  class Error < StandardError; end

  class << self
    attr_accessor :config

    # Accepts a block for configuring things.
    def configure
      self.config ||= Configuration.new
      yield(config) if block_given?

      raise Trailer::Error, 'Trailer is already configured' unless @recorder.nil?

      # Instantiate a new recorder after configuration.
      @storage = Trailer::Storage.factory(config.storage)
    end

    # Returns the recorder instance.
    def recorder
      raise Trailer::Error, 'Trailer.configure must be run before recording' if @storage.nil?

      Trailer::Recorder.new(@storage)
    end
  end
end
