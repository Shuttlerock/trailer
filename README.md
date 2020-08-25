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

The middleware will automatically trace exceptions as well, so you can see for a particular `trace_id` if anything went wrong.

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

## Searching for traces in AWS CloudWatch

CloudWatch allows you to search for specific attributes:

- Search for a specific `order_id`: `{ $.order_id = "aaa" }`
- Search for all records from a particular request or job: `{ $.trace_id = "1-5f44617e-6bcd7259689e5d303d4ad430" }`)
- Search for multiple attributes: `{ $.order_id = "order-aaa" && $.duration = 1 }`
- Search for one of several attributes: `{ $.order_id = "aaa" || $.order_id = "bbb" }`
- Search for a specific user: `{ $.current_user_id = 1234 }`
- Search for all records containing a particular attribute, regardless of its value: `{ $.duration = * }`

Trailer provides some standard attributes that might be useful:

Attribute      | Description
---------------|-------------|
`duration`     | The duration of the trace in milliseconds.
`host_name`    | The (optional) host name specified during `Trailer.configure`.
`service_name` | The service name specified during `Trailer.configure`.
`trace_id`     | A unique ID identifying all records from a single request or Sidekiq job. This allows you to track all events within the context of a single request.

You can also filter by partial wildcard, search nested objects, and much more - see [Filter and Pattern Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html) for more information.

![Searching CloudWatch](https://static.shuttlerock-cdn.com/staff/dave/trailer-gem/CloudWatch_Screenshot.png)

## Todo

- Allow the trace ID to be set manually, in case we want to trace distributed systems.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/trailer.
