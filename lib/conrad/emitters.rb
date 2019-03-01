# frozen_string_literal: true

module Conrad
  # :nodoc:
  module Emitters
    autoload :Sqs,    'conrad/emitters/sqs'
    autoload :Stdout, 'conrad/emitters/stdout'
  end
end
