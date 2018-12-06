# frozen_string_literal: true

require 'json'

module OutreachAuditor
  # Formats a given Hash into a presentable JSON format.
  class JSONFormatter
    # Formats a given Hash into a presentable JSON format.
    #
    # @param event [Hash] event to be formatted
    #
    # @return [String] JSON formatted string
    def call(event)
      event.to_json
    end
  end
end
