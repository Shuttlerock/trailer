# frozen_string_literal: true

module Trailer::Middleware
  class Sidekiq
    def call(_worker, _job, _queue)
      RequestStore.store[:trailer] ||= Trailer.new
      RequestStore.store[:trailer].start
      yield
    rescue Exception => e # rubocop:disable Lint/RescueException
      RequestStore.store[:trailer].add_exception(e)
      raise e
    ensure
      RequestStore.store[:trailer].finish
    end
  end
end
