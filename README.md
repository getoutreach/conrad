# Conrad

A general purpose tool for processing and emitting events to be consumed by other systems. Conrad is named for Hermes Conrad, Grade 36 Bureaucrat.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'conrad', git: 'https://github.com/getoutreach/conrad'
```

And then execute:

    $ bundle install

## Architecture

Conrad is built with a Rack-like architecture in mind in order to be familiar to many people. However, there are two special kinds of processors in the stack: the formatter and the emitter. These are guaranteed to be the last two objects called and handle formatting the final Hash and emitting it via your desired output.

1. Create an instance of `Conrad::Recorder`
2. Pass a Hash to `Conrad::Recorder#audit_event`.
3. This hash is run through various user-defined processors. Each of these must respond to `call` and return the event Hash to be used by the next processor in the cycle.
4. After the processor cycle, the hash is passed to the configured formatter to be converted into the desired format for emitting.
5. The final value is passed to the configured emitter and emitted.

Alternatively, you can use and configure a `Conrad::Collector` to collect batches of events that might share common metadata, such as a `request_id` for a web server that needs to be tracked across all events. Using `Conrad::Collector.current` to `add_event`s gives you access to an instance of `Conrad::Collector` per thread. You can configure default processors, emitter, and formatters for `Conrad::Collector`s by configuring the relevant `default_` attributes. There is also an option to emit the events as a batch by creating an emitter capable of accepting an Array of formatted events. The written emitter then handles the batch however it wishes.

### Processors

Processors can be configured using a keyword arg via the `Conrad::Recorder` initialization:
```ruby
class MyAuditProcessor
  def self.call(event)
    event[:foobar] = 'some value'
    event
  end
end

Conrad::Recorder.new(processors: [Conrad::Processors::AddTimestamp.new(:seconds), MyAuditProcessor, -> (event) { event[:proc] = 3; event }])
```

The only requirements are that:
1) It must respond to `call` whether that be as a Proc, lambda, class, or instance of something. Note: instances will not be regenerated on every call; a single instance would be shared across the Recorder's, and by extension the script's, lifetime.
2) That `call` method should return a new Hash for the next processor.

You may also halt the processing flow by having any processor `throw :halt_conrad_processing`. This will discard the audit event and stop processing at that point.

#### Included Processors

* `AddTimestamp` - Adds a `:timestamp` attribute to your event in either seconds or milliseconds since the epoch.
* `AddUUID` - Adds an `:event_uuid` attribute to your event.
* `Envelope` - Wraps an event in a defined envelope structure.

Be sure to examine the docs for any processors for more detailed usage.

### Formatter

The Formatter should be focused on formatting the final Hash into a suitable object for emitting, most likely a String. It should make no more modifications to the Hash in terms of adding or removing keys and stick to formatting values and the entire Hash itself. It should be able to respond to `call` and return the resulting value to be passed on to the emitter.

#### Included Formatters

* `JSON` - Formats the hash into a JSON format.

### Emitter

The Emitter should be responsible for pushing your event somewhere, whether that be to STDOUT, a log file, or some external service. Like the rest of the project, the configured object must respond to `call` and no guarantee project-wide is made of the return value.

#### Included Emitters

* `Stdout` - Emits the stringified event with a `puts` call.
* `Sqs` - Emits the stringified event to an SQS queue using a region, url and your access key and secret key.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/outreach/conrad. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Conrad project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/getoutreach/conrad/blob/master/CODE_OF_CONDUCT.md).
