module Conrad
  # Processor class used to take a given event, extract a set of attributes from
  # it, then wrap the remaining attributes into a payload attribute. This allows
  # downstream consumers to know about the outermost structure (the envelope)
  # without needing to account for all possible permutations of the event. This
  # also allows routing through various systems on a small number of values. If
  # a given envelope key does not exist in the original event, then it will be
  # set to nil in the resulting event.
  #
  # When using this processor, it is highly recommended that this be the last
  # processor unless you need to act on the wrapped event.
  #
  # @attribute envelope_keys [r]
  # @attribute payload_key [r]
  class Envelope
    attr_reader :envelope_keys, :payload_key

    # @param envelope_keys [Array<Symbol>] the keys to extract from the event.
    #   NOTE: These must be exact matches of both value and type (i.e. Strings
    #   and Symbols should not be considered interchangeable, and the event
    #   must be created with the attribute keys matching the types given here)
    # @param payload_key [Symbol] key to wrap the remainder of the event inside
    def initialize(envelope_keys, payload_key: :payload)
      raise TypeError, 'envelope_keys must be an Array' unless envelope_keys.is_a? Array

      @envelope_keys = envelope_keys
      @payload_key = payload_key
    end

    # @param event [Hash] event to be wrapped in the configured envelope
    #
    # @return [Hash] the wrapped event
    def call(event)
      envelope = envelope_keys.each_with_object({}) do |key, obj|
        obj[key] = event.delete(key)
      end

      envelope.merge(payload_key => event)
    end
  end
end
