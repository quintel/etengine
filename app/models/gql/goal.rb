# This is a very dumb object. An array of them is store in Gql::Gql#goals
#
module Gql
  class Goal
    attr_accessor :key

    def initialize(key)
      self.key = key
    end
  end
end