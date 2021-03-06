FactoryBot.define do
  factory :scenario do
    title "Some scenario"
    area_code "nl"
    end_year 2040
  end

  factory :scenario_visible_in_homepage, parent: :scenario do
    in_start_menu true
  end

  factory :scenario_attachment do
    key { 'interconnector_1_price_curve' }
    scenario
  end
end
