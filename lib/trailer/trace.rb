# frozen_string_literal: true

require 'trailer/destination'

class Trailer::Trace
  def initialize
    @destination = Trailer::Destination.factory
  end

  private

  attr_accessor :destination
end
