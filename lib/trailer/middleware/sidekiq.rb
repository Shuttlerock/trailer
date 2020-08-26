# frozen_string_literal: true

module Trailer
  module Middleware
    class Sidekiq
      def call(_worker, _job, _queue)
        if Trailer.enabled?
          RequestStore.store[:trailer] ||= Trailer.new
          RequestStore.store[:trailer].start
        end
        yield
      rescue Exception => e # rubocop:disable Lint/RescueException
        RequestStore.store[:trailer].add_exception(e) if Trailer.enabled?
        raise e
      ensure
        RequestStore.store[:trailer].finish if Trailer.enabled?
      end
    end
  end
end
