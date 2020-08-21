# frozen_string_literal: true

require 'trailer/configuration'
require 'trailer/version'
require 'trailer/trace'

module Trailer
  class Error < StandardError; end

  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config) if block_given?
  end
end
