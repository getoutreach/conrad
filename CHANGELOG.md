# Conrad Changelog

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
