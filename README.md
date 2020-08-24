# Trailer

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/trailer`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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
  # Required fields
  config.application_name      = 'shuttlerock' # The global application or company name.
  config.aws_access_key_id     = 'XXXXXXXXXXXXXXXXXXXX'
  config.aws_secret_access_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  config.service_name          = 'auth' # The name of the service within the application.

  # Optional fields
  config.auto_tag_fields       = /(_id|_at)$/.freeze                 # Optional - defaults to tag with any fields ending with '_id' or '_at'.
  config.aws_region            = 'us-east-1'                         # Optional, defaults to 'us-east-1'.
  config.host_name             = 'web.1'                             # Optional - the name of the individual host or server within the service.
  config.tag_fields            = %w(name role state status type url) # Optional - When tracing ActiveRecord instances, we can tag our trace with these fields explicitly.
end
```

### Plain Ruby

```
trail = Trailer.new
trail.start

# Do some operations
...
order = Order.new(state: :open)
order.save!
trail.write(order_id: order.id, state: order.state)

# Do some more operations
...
order.update(state: :closed, price_cents: 1_000)
trail.write(order_id: order.id, state: order.state, price: order.price_cents)

# Finish, and flush data to storage.
trail.finish
```

### Rails

Trailer middleware will be automatically added to Rails for you. Trailer::Concern provides a `with_trail()` method to simplify the tracing of objects:

```
class PagesController < ApplicationController
  include Trailer::Concern

  def index
    book = Book.find(params[:id])

    with_trail(:list_pages, book) do
      expensive_operation(book)
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

The `with_trail` method will trace an event with the given name (eg. `:destroy_page`), and tag the event with attributes pulled from the ActiveRecord instance, as well as the duration of the operation and a global `trace_id` for the request. You can customize which fields are used to tag the trace with the `config.auto_tag_fields` regex and / or the `config.tag_fields` array configuration options.

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

## Storage

Currently the only supported storage backend is AWS CloudWatch Logs. New backends should include [Concurrent::Async](https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/Async.html) from [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby) in order to provide non-blocking writes.

# Todo

- Provide a class instead of a string when configuring the backend, so 3rd-party backends can easily be used.
- Add Sidekiq middleware.
- Catch and log exceptions.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/trailer.
