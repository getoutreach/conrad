module Conrad
  module Emitters
    # Basic emitter for sending events to AWS's sqs.
    class Sqs
      def call(event)
        sqs = Aws::SQS::Client.new(
            region: ENV['SQS_REGION'],
            access_key_id: ENV['SQS_ACCESS_KEY_ID'],
            secret_access_key: ENV['SQS_SECRET_ACCESS_KEY'])
        sqs.send_message(queue_url: ENV['SQS_QUEUE_URL'], message_body: event)
      end
    end
  end
end
