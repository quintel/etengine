# frozen_string_literal: true

class RemoveMicroChpInputOm < ActiveRecord::Migration[5.1]
  SCENARIO_IDS = [
    361017, 361024, 361033, 361039, 361042, 362561, 362698, 362701, 362702,
    362705, 362708, 362710, 362712, 362719, 362724, 362774, 362775, 362776,
    362778, 362779, 362784, 362796, 362797, 362800, 362813, 362821, 362822,
    362826, 362827, 362828, 363625, 363626, 363639, 363641, 363643, 363644,
    363646, 363671, 363673, 363674, 363675, 363677, 363679, 364359, 364361,
    364363, 364365, 369748, 370161, 370165, 370167, 370316, 370376, 370539,
    371300, 371303, 371304, 371305, 371307, 371311, 371313, 371329, 371331,
    371333, 371667, 392431, 392442, 392446, 392448, 392458, 392459, 392462,
    392467, 392475, 392494, 392523, 392526, 392585, 392586, 392588, 392614,
    392628, 392637, 392651, 392653, 392664, 392668, 393020, 393034, 393039,
    393041, 393042, 393044, 393046, 393047, 393068, 393073, 393075, 393077,
    393079, 393081, 393097, 393119, 393131, 393133, 393140, 394273, 395436,
    395450
  ].freeze

  SOURCE_KEY = 'households_heater_micro_chp_network_gas_share'
  TARGET_KEY = 'households_heater_combined_network_gas_share'

  def up
    return unless Rails.env.production?

    say "#{scenarios.count} scenarios to be checked..."
    updated = 0

    scenarios.find_each.with_index do |scenario, index|
      say "#{index} done" if index.positive? && (index % 250).zero?

      if collection_name(scenario, SOURCE_KEY) && collection_name(scenario, TARGET_KEY)
        updated += 1

        source_collection = scenario.public_send(collection_name(scenario, SOURCE_KEY))
        target_collection = scenario.public_send(collection_name(scenario, TARGET_KEY))

        target_collection[TARGET_KEY] += source_collection[SOURCE_KEY]
        source_collection.delete(SOURCE_KEY)

        scenario.save(validate: false, touch: false)
      end
    end

    say "Finished. Updated #{updated} scenarios."
  end

  def down
    return unless Rails.env.production?
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def collection_name(scenario, input)
    if scenario.user_values[input]
      :user_values
    elsif scenario.balanced_values[input]
      :balanced_values
    end
  end

  def scenarios
    Scenario.where(id: SCENARIO_IDS)
  end
end
