# frozen_string_literal: true

class ScenarioUpdater

  class ShareGroups
    def self.each(values)
      group_names = values.keys.filter_map do |key|
        Input.get(key)&.share_group&.presence
      end.uniq

      Input.inputs_grouped.slice(*group_names).each do |name, inputs|
        yield name, inputs
      end
    end
  end
end
