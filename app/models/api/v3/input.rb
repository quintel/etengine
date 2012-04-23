module Api
  module V3
    class Input < ::Input
      def scenario
        Current.scenario
      end

      def gql
        scenario.gql
      end

      def to_json(options = {})
        Jbuilder.encode do |json|
          json.code key
          json.share_group share_group
          json.max max_value_for(gql)
          json.min min_value_for(gql)
          json.default start_value_for(gql)
          json.disabled true if disabled_in_current_area?
          json.label label if label = full_label_for(gql)
          if user_value = scenario.user_values[id]
            json.user_value user_value
          end
        end
      end
    end
  end
end
