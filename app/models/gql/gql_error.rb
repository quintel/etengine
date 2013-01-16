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

end
