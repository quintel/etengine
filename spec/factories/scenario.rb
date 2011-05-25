Factory.define :api_scenario do |api_scenario|
  api_scenario.title {"API"}
  api_scenario.api_session_key { 123456789 }
end

Factory.define :scenario do |scenario|
  scenario.title {"Some scenario"}
end

Factory.define :scenario_visible_in_homepage, :parent => :scenario do |f|
  f.in_start_menu true
end
