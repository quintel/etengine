# This is a very basic object
# All it does is remembering his own key and store the various instances
#
module Gql
  class Goal
    attr_accessor :key

    def initialize(key)
      self.key = key
    end

    class << self
      # Small identity map
      #
      def find(key)
        @goals ||= {}
        @goals[key] ||= new(key)
      end

      # Array containing all goals
      #
      def all
        @goals ||= {}
        @goals.values
      end

      # Clear the goals array
      #
      def clear
        @goals = {}
      end
    end
  end
end