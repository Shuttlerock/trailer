# frozen_string_literal: true

module Trailer
  module Middleware
    class Rack
      def initialize(app)
        @app = app
      end

      def call(env)
        RequestStore.store[:trailer] ||= Trailer.new
        RequestStore.store[:trailer].start
        @app.call(env)
      rescue Exception => e # rubocop:disable Lint/RescueException
        RequestStore.store[:trailer].add_exception(e)
        raise e
      ensure
        RequestStore.store[:trailer].finish
      end
    end
  end
end
