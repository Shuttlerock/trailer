# frozen_string_literal: true

require 'trailer/concern'
require 'trailer/configuration'
require 'trailer/middleware/rack'
require 'trailer/middleware/sidekiq'
require 'trailer/railtie' if defined?(Rails::Railtie)
require 'trailer/recorder'
require 'trailer/version'

module Trailer
  class Error < StandardError; end

  class << self
    attr_accessor :config

    # Accepts a block for configuring things.
    def configure
      self.config ||= Configuration.new
      yield(config) if block_given?

      # Instantiate a new recorder after configuration.
      @storage = config.storage.new
    end

    # Returns a new recorder instance.
    def new
      raise Trailer::Error, 'Trailer.configure must be run before recording' if @storage.nil?

      Trailer::Recorder.new(@storage)
    end
  end
end
