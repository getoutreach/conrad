# OutreachAuditor

A general purpose tool for processing and emitting events to be consumed by other systems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'outreach_auditor', git: 'https://github.com/outreach/outreach_auditor'
```

And then execute:

    $ bundle

## Usage

### Architecture

OutreachAuditor is built with a Rack-like architecture in mind in order to be familiar to many people. However, there are two special kinds of "middleware" in the stack: the formatter and the emitter. These are guaranteed to be the last two pieces of middleware run and handle formatting the final Hash and emitting it via your desired output.

1. A program calls `OutreachAuditor.audit_event` with a Hash.
2. This hash is run through various user-defined middlewares. Each of these must respond to `call` and return the modified event Hash.
3. After the middleware cycle, the Hash is validated to confirm that it contains no instances of anything not included in the SCALAR_TYPES.
4. The hash is then passed to the configured formatter to be converted into the desired format for emitting.
5. The final value is passed to the configured emitter and emitted.

### Middleware

Middleware can be configured using an attribute accessor via the OutreachAuditor configuration:
```ruby
class MyAuditMiddleware
  def self.call(event)
    event[:foobar] = 'some value'
    event
  end
end

OutreachAuditor::Recorder.new(middlewares: [TimestampMiddleware.new(:seconds), MyAuditMiddleware, -> (event) { event[:proc] = 3; event }])
```

The only requirements are that:
1) It must respond to `call` whether that be as a Proc, lambda, class, or instance of something. Note: instances will not be regenerated on every call; a single instance would be shared across the OutreachAuditor's, and by extension the script's, lifetime.
2) That `call` method should return a new Hash for the next piece of middleware.

### Included Middleware

* `TimestampMiddleware` - Adds a `:timestamp` attribute to your event in either seconds or milliseconds since the epoch. Usage: `require 'outreach_auditor/timestamp_middleware'` then include `OutreachAuditor::TimestampMiddleware.new(:seconds)` or `TOutreachAuditor::imestampMiddleware.new(:milliseconds)` (depending on if you want units of seconds or milliseconds respectively) in your middleware configured Array.

### Formatter

The Formatter should be focused on formatting the final Hash into a suitable object for emitting, most likely a String. It should make no more modifications to the Hash in terms of adding or removing keys and stick to formatting values and the entire Hash itself. It should be able to respond to `call` and return the resulting value to be passed on to the emitter. The project includes a `JSONFormatter` for ease of use.

### Emitter

The Emitter should be responsible for pushing your event somewhere, whether that be to STDOUT, a log file, or some external service. Like the rest of the project, the configured object must respond to `call` and no guarantee project-wide is made of the return value. The project comes with the `StdoutEmitter` for emitting to STDOUT.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/outreach/outreach_auditor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OutreachAuditor project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/getoutreach/outreach_auditor/blob/master/CODE_OF_CONDUCT.md).
