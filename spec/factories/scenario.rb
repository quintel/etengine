Factory.define :api_scenario do |f|
  f.title "API"
  f.api_session_key 123456789
end

Factory.define :scenario do |f|
  f.title "Some scenario"
  f.region "abc"
  f.country "nl"
  f.end_year 2040
  f.use_fce false
end

Factory.define :scenario_visible_in_homepage, :parent => :scenario do |f|
  f.in_start_menu true
end
