# Conrad Changelog

## Version 2.2.0
* Bug fix: ensure that `Conrad::Collector` metadata is reset even when emitting raises an error [#20](https://github.com/getoutreach/conrad/pull/20/)
* Bug fix: errors on emitting individual events does not prevent the collector from emitting the rest [#20](https://github.com/getoutreach/conrad/pull/20/)
* Bug fix: expose API for adding event metadata for `Conrad::Collector` [#20](https://github.com/getoutreach/conrad/pull/20/)
* Add logger to `Conrad::Collector` [#20](https://github.com/getoutreach/conrad/pull/20/)

## Version 2.1.0
* Add `Conrad::Collector` for collecting batches of events [#16](https://github.com/getoutreach/conrad/pull/16)

## Version 2.0.0
* Added ability to wrap events in an Envelope [#13](https://github.com/getoutreach/conrad/pull/13)
* **BREAKING CHANGE** Nested provided Processors, Emitters, and Formatters inside of modules and folders [#14](https://github.com/getoutreach/conrad/pull/14)
* Introduced an emitter for sending events to SQS [#14](https://github.com/getoutreach/conrad/pull/14)

## Version 1.0.0

* Added ability to add a UUID to an event
* **BREAKING CHANGE** Renamed middlewares to processors
* **BREAKING CHANGE** Changed timestamp processor to accept keyword args
* Added ability to change timestamp attribute key for timestamp processor
* Convert to Circle - [#7](https://github.com/getoutreach/conrad/commit/e94d17b2ef880bba2e48ca9cc8be2c9b51608a8a)
* Allow throwing `:halt_conrad_processing` to stop processing and throw away an event - [#8](https://github.com/getoutreach/conrad/commit/a0aa6128b3b34db9bce941a0d3e6feccd11b9139)

## Version 0.1.0

* Added `StdoutEmitter`
* Added `JSONFormatter`
* Added `TimestampMiddleware`
* Added ability to record audit events and emit them
