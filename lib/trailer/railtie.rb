# frozen_string_literal: true

class Trailer::Railtie < ::Rails::Railtie
  initializer 'trailer.insert_middleware' do |app|
    app.config.middleware.insert_after RequestStore::Middleware, Trailer::Middleware::Rack if defined?(RequestStore::Middleware)
  end
end
