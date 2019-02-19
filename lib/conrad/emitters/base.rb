require 'conrad/errors'

module Conrad
  # A module containing all of conrad's built in event emitters for outputting
  # events
  module Emitters
    # Basic emitter for sending events to AWS's sqs. If all access information
    # is given, the given credentials will be used. Otherwise, the emitter will
    # attempt to use values configured in the running environment according to
    # the AWS SDK documentation (such as from ~/.aws/credentials).
    class Base
      def call(event, background_delivery: false)
        unless background_delivery
          emit(event)
        end
      end
    end
  end
end