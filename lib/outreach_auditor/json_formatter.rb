require 'json'

module OutreachAuditor
  # Formats a given Hash into a presentable JSON format.
  class JSONFormatter
    # Formats a given Hash into a presentable JSON format.
    #
    # @return [String]
    def call(_event)
      recordable_event.to_json
    end
  end
end
