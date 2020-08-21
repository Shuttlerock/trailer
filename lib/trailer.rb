# frozen_string_literal: true

require 'trailer/configuration'
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
    end

    # Returns a new client.
    def new
      # If we haven't configured anything yet, use the defaults.
      self.config ||= Trailer::Configuration.new
      Trailer::Recorder.new
    end
  end
end
