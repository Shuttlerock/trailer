# frozen_string_literal: true

module Trailer::Middleware
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      RequestStore.store[:trailer] ||= Trailer.recorder
      RequestStore.store[:trailer].start
      @app.call(env)
    rescue Exception => e # rubocop:disable Lint/RescueException
      # TODO: store exceptions.
      # RequestStore.store[:trailer].add_exception(err)
      raise e
    ensure
      RequestStore.store[:trailer].finish
    end
  end
end
