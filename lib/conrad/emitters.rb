# frozen_string_literal: true

module Conrad
  module Emitters
    autoload :Base,   'conrad/emitters/base'
    autoload :Sqs,    'conrad/emitters/sqs'
    autoload :Stdout, 'conrad/emitters/stdout'
  end
end
