# This is a very dumb object. An array of them is store in Gql::Gql#goals
#
module Gql
  class Goal
    attr_accessor :key, :user_value

    def initialize(key)
      self.key = key
    end
    
    def is_set?
      !user_value.nil?
    end
  end
end