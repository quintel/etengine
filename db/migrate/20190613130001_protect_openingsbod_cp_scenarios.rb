class ProtectOpeningsbodCpScenarios < ActiveRecord::Migration[5.1]
  def change
    return unless Rails.env.production?

    reversible do |dir|
      dir.up { scenarios.update_all(protected: true) }
      dir.down { scenarios.update_all(protected: false) }
    end
  end

  private

  def scenarios
    ids = Pathname.new(__FILE__)
      .expand_path
      .dirname
      .join('20190613130000_protect_openingsbod_cp_scenarios/scenario_ids.csv')
      .read
      .lines
      .map(&:to_i)

    Scenario.where(id: ids)
  end
end
