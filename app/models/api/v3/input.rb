module Api
  module V3
    class Input < ::Input
      def gql
        Current.scenario.gql
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
        end
      end
    end
  end
end
