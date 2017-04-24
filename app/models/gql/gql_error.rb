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

end
