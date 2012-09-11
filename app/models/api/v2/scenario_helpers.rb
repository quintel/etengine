module Api
  module V2
    module ScenarioHelpers
      extend ActiveSupport::Concern

      # The values for the sliders for this api_scenario
      #
      def input_values
        values = Rails.cache.fetch("inputs.user_values.#{area_code}") do
          Input.static_values(gql)
        end

        Input.dynamic_start_values(gql).each do |id, dynamic_values|
          values[id][:start_value] = dynamic_values[:start_value] if values[id]
        end

        balanced_values.each do |id, balanced_value|
          values[id][:user_value] = balanced_value if values[id]
        end

        user_values.each do |id, user_value|
          values[id][:user_value] = user_value if values[id]
        end

        values
      end

      def api_errors
        if used_groups_add_up?
          []
        else
          groups = used_groups_not_adding_up
          remove_groups_and_elements_not_adding_up!
          groups.map do |group, elements|
            element_ids = elements.map{|e| "#{e.id} [#{e.key || 'no_key'}]" }.join(', ')
            "Group '#{group}' does not add up to 100. Elements (#{element_ids}) "
          end
        end
      end

      # API requests make use of this. Check Api::ApiScenariosController#new
      #
      def as_json(options={})
        super(
          :only => [:user_values, :area_code, :end_year, :start_year, :id, :use_fce]
        )
      end
    end
  end
end
