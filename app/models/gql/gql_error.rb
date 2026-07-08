module Gql

  class GqlError < StandardError
    def initialize(message = nil)
      super(message)
    end
  end

  class NoSuchInputError < GqlError
    def initialize(key)
      super "No input exists with the key #{ key.inspect }"
    end
  end

  class TimeCurveError < GqlError
    def initialize(curve, attribute = nil)
      if attribute
        super "No attribute named #{ attribute.inspect } in the " \
              "#{ curve.inspect } curve"
      else
        super "No such time curve: #{ curve.inspect }"
      end
    end
  end

  # Raised when a SECTOR/MSECTOR/EMISSIONS scheme-form query names a
  # classification scheme which does not exist in the sector mapping.
  class UnknownSectorSchemeError < GqlError
    def initialize(scheme, valid_schemes)
      super("Unknown sector mapping scheme #{scheme.inspect}. " \
            "Valid schemes: #{valid_schemes.map(&:inspect).join(', ')}.")
    end
  end

  # Raised when a SECTOR/MSECTOR/EMISSIONS scheme-form query names a value
  # which does not appear in that scheme's column.
  class UnknownSectorValueError < GqlError
    def initialize(scheme, value)
      super("Unknown value #{value.inspect} for sector mapping scheme " \
            "#{scheme.inspect}.")
    end
  end
end
