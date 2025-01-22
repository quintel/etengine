module Gql::Runtime
  module Functions
    module Policy

      # Returns a Qernel::Goal object with the key passed as parameter.
      # The object will be created if it doesn't exist
      #
      def GOAL(key)
        scope.graph.find_or_create_goal(key.to_sym)
      end

      # returns a boolean whether the user has set a goal or not.
      # I'd rather have the VALUE(GOAL(foo); user_value) return nil, but
      # now falsy values are converted to 0.0 unfortunately.
      #
      def GOAL_IS_SET(key)
        GOAL(key).is_set?
      rescue
        nil
      end

      # Shortcut for
      # V(GOAL(foobar);user_value)
      #
      def GOAL_USER_VALUE(key)
        GOAL(key).user_value
      end

    end
  end
end
