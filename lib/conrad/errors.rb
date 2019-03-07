# frozen_string_literal: true

module Conrad
  # Base error class
  class Error < StandardError
    # :nodoc:
    def to_s
      'An unexpected error has occurred'
    end
  end

  # Error for responding with issues around kinesis credential creation
  class InvalidAwsCredentials < Error
    # :nodoc:
    def to_s
      'Must provide secret_access_key and access_key_id OR rely ' \
      'on configured values in the running environment.'
    end
  end

  # Error raised when the value of an event attribute is not of one of the
  # allowed types
  class ForbiddenValue < Error
    def initialize(key, value)
      @key = key
      @value = value
    end

    # :nodoc:
    def to_s
      "Key of #{@key} provided invalid value type of #{@value.class}"
    end
  end

  # Error raised when the key of an event attribute is not of one of the
  # allowed types
  class ForbiddenKey < Error
    def initialize(key)
      @key = key
    end

    # :nodoc:
    def to_s
      "Invalid key #{@key}. Keys must be either Strings or Symbols"
    end
  end
end
