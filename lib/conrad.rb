require 'conrad/version'

# :nodoc:
module Conrad
  autoload :Collector,      'conrad/collector'
  autoload :Errors,         'conrad/errors'
  autoload :EmitterQueue,   'conrad/emitter_queue'
  autoload :Emitters,       'conrad/emitters'
  autoload :Formatters,     'conrad/formatters'
  autoload :Processors,     'conrad/processors'
  autoload :ProcessorStack, 'conrad/processor_stack'
  autoload :Recorder,       'conrad/recorder'

  class << self
    # Boolean indicating if the events collected should be emitted in the
    # background. Defaults to false.
    def background_emit?
      EmitterQueue.instance.background
    end

    def background_emit=(value)
      EmitterQueue.instance.background = value
    end
  end
end
