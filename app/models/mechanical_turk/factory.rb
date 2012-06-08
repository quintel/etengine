module MechanicalTurk
  class Factory
    def initialize(json)
      @data = JSON.parse(json)
    end

    def settings_for_load_gql
      settings.slice(:area_code, :end_year).map do |key, value|
        "#{key}: #{value.inspect}"
      end.join(", ")
    end

    def results
      @data['result']
    end

    def custom
      results.dup.delete_if{|k,v| k.include?("(")}
    end

    def charts
      results.dup.delete_if{|k,v| k.include?("dashboard_") || 
                                  k.include?("peak_load") || 
                                  k.include?("policy_goal") ||
                                  k.include?("(")}
    end

    def dashboard
      results.dup.delete_if{|k,v| !k.include?("dashboard_")}
    end

    def settings
      (@data['settings'] || {}).with_indifferent_access
    end
  end
end