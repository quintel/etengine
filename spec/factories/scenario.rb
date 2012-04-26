Factory.define :scenario do |f|
  f.title "Some scenario"
  f.area_code "nl"
  f.end_year 2040
  f.use_fce false
end

Factory.define :scenario_visible_in_homepage, :parent => :scenario do |f|
  f.in_start_menu true
end
