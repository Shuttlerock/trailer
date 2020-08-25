# frozen_string_literal: true

class Trailer::Railtie < ::Rails::Railtie
  initializer 'trailer.insert_middleware' do |app|
    # Rack middleware.
    app.config.middleware.insert_after RequestStore::Middleware, Trailer::Middleware::Rack if defined?(RequestStore::Middleware)

    # Sidekiq middleware.
    if defined?(::Sidekiq)
      ::Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Trailer::Middleware::Sidekiq
        end
      end
    end
  end
end
