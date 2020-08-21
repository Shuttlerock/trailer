# frozen_string_literal: true

require 'active_support/inflector'
require 'shuttlerock_tracer/destination/cloud_watch'

module ShuttlerockTracer::Destination
  def self.factory
    klass = ActiveSupport::Inflector.classify("shuttlerock_tracer/destination/#{ShuttlerockTracer.config.destination}")
    ActiveSupport::Inflector.constantize(klass).new
  end
end
