# frozen_string_literal: true

require 'shuttlerock_tracer/destination'

class ShuttlerockTracer::Trace
  def initialize
    @destination = ShuttlerockTracer::Destination.factory
  end

  private

  attr_accessor :destination
end
