# frozen_string_literal: true

module Trailer
  module Middleware
    class Rack
      def initialize(app)
        @app = app
      end

      def call(env)
        if Trailer.enabled?
          RequestStore.store[:trailer] ||= Trailer.new
          RequestStore.store[:trailer].start
        end
        @app.call(env)
      rescue Exception => e # rubocop:disable Lint/RescueException
        RequestStore.store[:trailer].add_exception(e) if Trailer.enabled?
        raise e
      ensure
        RequestStore.store[:trailer].finish if Trailer.enabled?
      end
    end
  end
end
