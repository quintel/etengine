Factory.define :dataset do |f|
  f.association :area, :factory => :area
  f.region_code {|d| d.area.country }
end