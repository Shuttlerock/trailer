# Trailer

Trailer provides a Ruby framework for tracing events in the context of a request or background job. It allows you to easily tag and log events with metadata, so that you can easily search later for e.g. all events and exceptions related to a particular order.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trailer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trailer

## Usage

### Configuration

Configure the gem in `config/initializers/trailer.rb`:

```
Trailer.configure do |config|
  config.application_name      = 'shuttlerock'
  config.aws_access_key_id     = 'XXXXXXXXXXXXXXXXXXXX'
  config.aws_secret_access_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  config.service_name          = 'auth'
end
```

Option                  | Required?                         | Default                        | Description
------------------------|-----------------------------------|--------------------------------|-------------|
`application_name`      | Yes                               |                                | The global application or company name. |
`auto_tag_fields`       |                                   | `/(_id\|_at)$/`                | When tracing ActiveRecord instances, we can tag our trace with fields matching this regex. |
`aws_access_key_id`     | Yes (if using CloudWatch storage) |                                | AWS access key with CloudWatch write permission. |
`aws_region`            |                                   | `'us-east-1'`                  | The AWS region to log to. |
`aws_secret_access_key` | Yes (if using CloudWatch storage) |                                | The AWS secret key. |
`current_user_method`   |                                   |                                | Allows you provide the name of a method (eg. `:current_user`) that provides a user instance. Trailer will automatically tag the `id` of this user if the option is provided (disabled by default). |
`host_name`             |                                   |                                | The name of the individual host or server within the service. |
`service_name`          | Yes                               |                                | The name of the service within the application. May consist of multiple hosts. |
`storage`               |                                   | `Trailer::Storage::CloudWatch` | The storage class to use. |
`tag_fields`            |                                   | `['name']`                     | When tracing ActiveRecord instances, tag the trace with these fields. |

### Plain Ruby

Tracing consists of a `start`, a number of `write`s, and a `finish`:

```
trail = Trailer.new
trail.start
...
order = Order.new(state: :open)
order.save!
trail.write(order_id: order.id, state: order.state)
...
order.update(state: :closed, price_cents: 1_000)
trail.write(order_id: order.id, state: order.state, price: order.price_cents)

# Finish, and flush data to storage.
trail.finish
```

Each call to `start` will create a unique trace ID, that will be persisted with each `write`, allowing you to e.g. search for all events related to a particular HTTP request. Data will not be persisted until `finish` is called. You can `start` and `finish` the same `Trailer` instance multiple times, as long as you `finish` the previous trace before you `start` a new one.

### Rails

`Trailer::Middleware::Rack` will be automatically added to Rails for you. `Trailer::Concern` provides a `with_trail()` method to simplify the tracing of objects:

```
class PagesController < ApplicationController
  include Trailer::Concern

  def index
    book = Book.find(params[:id])

    @pages = with_trail(:list_pages, book) do
      expensive_operation_to_list_pages(book)
    end
  end

  def destroy
    page = Page.find(params[:id])

    with_trail(:destroy_page, page) do
      page.destroy!
    end

    redirect_to pages_path
  end
end
```

The `with_trail` method will trace an event with the given name (e.g. `:destroy_page`), and tag the event with attributes pulled from the ActiveRecord instance, as well as the duration of the operation and a global `trace_id` for the request. You can customize which fields are used to tag the trace with the `config.auto_tag_fields` regex and / or the `config.tag_fields` array configuration options.

You can provide your own tags to `with_trail` to augment the automated tags:

```
with_trail(:destroy_page, page, tags: { user: current_user.id, role: user.role }) do
  page.destroy!
end
```

The concern is not restricted to Rails controllers - it should work with any Ruby class:

```
class ExpensiveService
  include Trailer::Concern

  def perform!(record)
    with_trail(:expensive_performance, record) do
      ...
    end
  end
end
```

### No Rails?

You can use the Middleware in any rack application. You'll have to add this somewhere:

```
use Trailer::Middleware::Rack
```

### Sidekiq

If you are using Rails, `Trailer::Middleware::Sidekiq` will be automatically added to the sidekiq middle chain for you. You can trace operations using the standard `Trailer::Concern` method:

```
class AuditJob < ApplicationJob
  include Trailer::Concern

  def perform(user)
    with_trail(:audit_user, user) do
      expensive_operation()
    end
  end
end
```

If you're' not using Rails, you'll need to add the Sidekiq middleware explicitly:

```
::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Trailer::Middleware::Sidekiq
  end
end
```

## Storage

Currently the only provided storage backend is AWS CloudWatch Logs, but you can easily implement your own backend if necessary. New backends should:

- Include [Concurrent::Async](https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/Async.html) from [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby) in order to provide non-blocking writes.
- Implement a `write` method that takes a hash as an argument.
- Implement a `flush` method that persists the data.

```
class MyStorage
  include Concurrent::Async

  def write(data)
    ...
  end

  def flush
    ...
  end
end

Trailer.configure do |config|
  config.storage = MyStorage
end
```

# Todo

- Catch and log exceptions.
- Allow the trace ID to be set manually, in case we want to trace distributed systems.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/trailer.
