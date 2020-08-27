[![CircleCI](https://circleci.com/gh/Shuttlerock/trailer/tree/master.svg?style=shield)](https://circleci.com/gh/Shuttlerock/workflows/trailer/tree/master)
[![Gem Version](https://badge.fury.io/rb/trailer.svg)](https://badge.fury.io/rb/trailer)

# Trailer

Trailer provides a Ruby framework for tracing events in the context of a request or background job. It allows you to tag and log events with metadata, so that you can search later for e.g. all events and exceptions related to a particular request.

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
`application_name`      | Yes                               |                                | The global application or company name. This can also be configured with the `TRAILER_APPLICATION_NAME` environment variable. |
`auto_tag_fields`       |                                   | `/(_id\|_at)$/`                | When tracing ActiveRecord instances, automatically tag the trace with fields matching this regex. |
`aws_access_key_id`     | Yes (if using CloudWatch storage) |                                | AWS access key with CloudWatch write permission. |
`aws_region`            |                                   | `'us-east-1'`                  | The AWS region to log to. |
`aws_secret_access_key` | Yes (if using CloudWatch storage) |                                | The AWS secret key. |
`current_user_method`   |                                   |                                | Allows you provide the name of a method (eg. `:current_user`) that provides a user instance. Trailer will automatically tag the `id` of this user if the option is provided (disabled by default). |
`enabled`               |                                   | `true`                         | Allows tracing to be conditionally disabled. |
`environment`           |                                   |                                | The environment that the application is running (eg. `production`, `test`). This can also be configured with the `TRAILER_ENV`, `RAILS_ENV` or `RACK_ENV` environment variables. |
`host_name`             |                                   |                                | The name of the individual host or server within the service. This can also be configured with the `TRAILER_HOST_NAME` environment variable. |
`service_name`          | Yes                               |                                | The name of the service within the application. This can also be configured with the `TRAILER_SERVICE_NAME` environment variable. |
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

`Trailer::Middleware::Rack` will be automatically added to Rails for you. `Trailer::Concern` provides three methods to simplify the tracing of objects:

-  `trace_method`
-  `trace_class`
-  `trace_event`

The simplest way to start tracing is to include `Trailer::Concern` and wrap an operation with `trace_method`:

```
class PagesController < ApplicationController
  include Trailer::Concern

  def index
    trace_method do
      book = Book.find(params[:id])
      expensive_operation_to_list_pages(book)
    end
  end
end
```

Every time `index` is requested, Trailer will record that the method was called, and add some metadata:

```
{
  "event":        "PagesController#index",
  "duration":     112,
  "environment":  "production",
  "host_name":    "web.1",
  "service_name": "studio-api",
  "trace_id":     "1-5f465669-97185c244365a889fca9c6fc"
}
```

This is not particularly useful by itself - you didn't record anything about the book whose pages you are `index`ing. You can pass the `Book` instance to improve visibility:

```
def index
  book = Book.find(params[:id])

  trace_method(book) do
    expensive_operation_to_list_pages(book)
  end
end
```

Now every time `index` is requested you'll see `Book` metadata as well, such as the `book_id`, `author_id` and Rails timestamps:

```
{
  "event":        "PagesController#index",
  "book_id":      15,
  "author_id":    12,
  "created_at":   "2020-08-26 21:56:12 +0900",
  "updated_at":   "2020-08-26 21:57:05 +0900",
  ...
}
```

The `auto_tag_fields` and `tag_fields` configuration options are used to decide which fields from the `Book` instance you collect (see [Configuration](#configuration) for more details). The resource provided doesn't have to be an `ActiveRecord` instance - a `Hash` will work as well.

If you only want to record the class name rather than the class + method, use the `trace_class` method:

```
class ArchiveJob
  def perform(book)
    trace_class(book) do
      book.archive!
    end
  end
end
```

This will record `"event": "ArchiveJob"` instead of `"event": "ArchiveJob#perform"`. This is useful in situations where the method name doesn't provide any additional information (eg. background jobs always implement `perform`, and GraphQL resolvers implement `resolve`).

The `trace_event` method is similar `trace_method` and `trace_class`, but it requires an event name to be passed as the first argument:

```
class PagesController < ApplicationController
  include Trailer::Concern

  def index
    book = Book.find(params[:id])

    @pages = trace_event(:list_pages, book) do
      expensive_operation_to_list_pages(book)
    end
  end

  def destroy
    page = Page.find(params[:id])

    trace_event(:destroy_page, page) do
      page.destroy!
    end

    redirect_to pages_path
  end
end
```

You can also provide your own tags to any of the trace methods to augment the automated tags:

```
trace_event(:destroy_page, page, user: current_user.id, role: user.role) do
  page.destroy!
end
```

The concern is not restricted to Rails controllers - it should work with any Ruby class:

```
class ExpensiveService
  include Trailer::Concern

  def calculate(record)
    trace_event(:expensive_calculation, record) do
      ...
    end
  end
end
```

If you have a method similar to Devise's [current_user](https://github.com/heartcombo/devise#controller-filters-and-helpers), you can automatically augment the trace with the ID of the user performing the action:

```
# config/initializers/trailer.rb
Trailer.configure do |config|
  config.current_user_method = :current_user
end

# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  include Trailer::Concern

  def index
    book = Book.find(params[:id])

    trace_method(book) do
      expensive_operation_to_list_pages(book)
    end
  end

  def current_user
    User.find(session[:user_id])
  end
end
```

This will add the `current_user_id` to the trace metadata:

```
{
  "event":           "PagesController#index",
  "current_user_id": 26,
  ...
}
```

The middleware will automatically trace exceptions as well:

```
def index
  book = Book.find(params[:id])

  trace_method(book) do
    expensive_operation_to_list_pages(book)
  end

  raise StandardError, 'Something went wrong!'
end
```

This will record both the method call and the exception:

```
{
  "event":    "PagesController#index",
  "trace_id": "1-5f465669-97185c244365a889fca9c6fc",
  ...
}

{
  "exception": "StandardError",
  "message":   "Something went wrong!",
  "trace_id":  "1-5f465669-97185c244365a889fca9c6fc",
  "trace":     [...]
  ...
}
```

The result of the block is returned, so you can assign a trace to a variable:

```
record = trace_method(params[:advert]) do
  Advert.create(params[:advert])
end
```

Similarly, you can use a trace as the return value of a method:

```
def add(a, b)
  trace_method { a + b }
end
```


### No Rails?

You can use the Middleware in any rack application. You'll have to add this somewhere:

```
use Trailer::Middleware::Rack
```

### Sidekiq

If you are using Sidekiq, `Trailer::Middleware::Sidekiq` will be automatically added to the sidekiq middle chain for you. You can trace operations using the standard `Trailer::Concern` method:

```
class AuditJob < ApplicationJob
  include Trailer::Concern

  def perform(user)
    trace_class(user) do
      expensive_operation()
    end
  end
end
```

If you're not using Rails, you'll need to add the Sidekiq middleware explicitly:

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

## CloudWatch Permissions

The AWS account needs the following CloudWatch Logs permissions:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:XXXXXXXXXXXX:log-group:my-log-group-name",
                "arn:aws:logs:us-east-1:XXXXXXXXXXXX:log-group:my-log-group-name:log-stream:my-log-stream-name"
            ]
        }
    ]
}
```

The ARNs in the `Resource` section are for demonstration purposes only - substitute your own, or use `"Resource": "*"` to allow global access.

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

Bug reports and pull requests are welcome on GitHub at https://github.com/shuttlerock/trailer.
