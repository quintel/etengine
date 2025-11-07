# frozen_string_literal: true

class ScenarioUpdater

  class ShareGroups

    # This method resolves each incoming key and then processes the share groups associated with those values, so
    # it only processes the relevant share groups associated with the update being processed.
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
