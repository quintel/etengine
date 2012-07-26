FactoryGirl.define do
  factory :scenario do
    title "Some scenario"
    area_code "nl"
    end_year 2040
    use_fce false
  end

  factory :scenario_visible_in_homepage, parent: :scenario do
    in_start_menu true
  end
end
