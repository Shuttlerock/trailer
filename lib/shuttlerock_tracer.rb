# frozen_string_literal: true

require 'shuttlerock_tracer/configuration'
require 'shuttlerock_tracer/version'
require 'shuttlerock_tracer/trace'

module ShuttlerockTracer
  class Error < StandardError; end

  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config) if block_given?
  end
end
