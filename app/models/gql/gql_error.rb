module Gql

  class GqlError < StandardError
    def initialize(message = nil)
      super(message)
    end
  end

end
