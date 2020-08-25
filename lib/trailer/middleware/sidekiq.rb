# frozen_string_literal: true

module Trailer::Middleware
  class Sidekiq
    def call(_worker, _job, _queue)
      RequestStore.store[:trailer] ||= Trailer.new
      RequestStore.store[:trailer].start
      yield
    rescue Exception => e # rubocop:disable Lint/RescueException
      # TODO: store exceptions.
      # RequestStore.store[:trailer].add_exception(err)
      raise e
    ensure
      RequestStore.store[:trailer].finish
    end
  end
end
