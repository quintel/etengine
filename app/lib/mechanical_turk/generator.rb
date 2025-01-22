module MechanicalTurk
  class Generator
    def initialize(json, custom_sections = nil)
      @data = JSON.parse(json)
      if custom_sections == :all
        @sections = {gqueries: results}
      else
        @sections = {charts: charts, dashboard: dashboard}
      end
    end

    def settings_for_load_scenario
      settings.slice(:area_code, :end_year, :scenario_id).map do |key, value|
        "#{key}: #{value.inspect}"
      end.join(", ")
    end

    def render
      av = ActionView::Base.new("#{Rails.root}/lib/mechanical_turk/templates")
      av.render 'spec', generator: self
    end

    def sections
      @sections
    end

    def results
      @data['result'] || {}
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
