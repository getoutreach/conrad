require 'conrad/version'

# :nodoc:
module Conrad
  autoload :Collector,      'conrad/collector'
  autoload :Errors,         'conrad/errors'
  autoload :Emitters,       'conrad/emitters'
  autoload :Formatters,     'conrad/formatters'
  autoload :Processors,     'conrad/processors'
  autoload :ProcessorStack, 'conrad/processor_stack'
  autoload :Recorder,       'conrad/recorder'
end
