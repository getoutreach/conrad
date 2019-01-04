# frozen_string_literal: true

require 'json'

module Conrad
  # A module containing all of conrad's event formatters.
  module Formatters
    # Formats a given Hash into a presentable JSON format.
    class JSON
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
end
