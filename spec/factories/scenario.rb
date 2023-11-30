FactoryBot.define do
  factory :scenario do
    area_code { "nl" }
    end_year { 2040 }
  end

  factory :scenario_with_user_values, parent: :scenario do
    user_values do
      {
        foo_demand: 10.0,
        input_2: 20.0,
        input_3: 30.0
      }
    end
  end

  factory :scenario_visible_in_homepage, parent: :scenario do
    in_start_menu { true }
  end

  factory :scenario_attachment do
    key { 'interconnector_1_price_curve' }
    scenario
  end

  factory :scaled_scenario, parent: :scenario_with_user_values do
    scaler do
      ScenarioScaling.new(
        area_attribute: 'present_number_of_residences',
        base_value: 8_000_000.0,
        has_agriculture: true,
        has_energy: true,
        has_industry: false,
        value: 100.0
      )
    end
  end

  factory :heat_network_order do
    scenario
    order { HeatNetworkOrder.default_order.reverse }
  end

  factory :scenario_with_heat_network, parent: :scenario_with_user_values do
    after(:create) do |scenario, evaluator|
      create_list(:heat_network_order, 1, scenario: scenario)

      scenario.reload
    end
  end
end
