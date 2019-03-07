# frozen_string_literal: true

module Conrad
  # :nodoc:
  module Emitters
    autoload :AmazonBase, 'conrad/emitters/amazon_base'
    autoload :Kinesis,    'conrad/emitters/kinesis'
    autoload :Sqs,        'conrad/emitters/sqs'
    autoload :Stdout,     'conrad/emitters/stdout'
  end
end
