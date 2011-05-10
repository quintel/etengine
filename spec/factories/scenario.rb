Factory.define :scenario do |scenario|
  scenario.title {"Some scenario"}
end

Factory.define :scenario_visible_in_homepage, :parent => :scenario do |f|
  f.in_start_menu true
end
