# frozen_string_literal: true

require 'active_support/inflector'
require 'trailer/destination/cloud_watch'

module Trailer::Destination
  def self.factory
    klass = ActiveSupport::Inflector.classify("trailer/destination/#{Trailer.config.destination}")
    ActiveSupport::Inflector.constantize(klass).new
  end
end
