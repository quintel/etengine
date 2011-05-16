Factory.define :carrier_data, :class => Dataset::CarrierData do |f|
  f.association :area, :factory => :area
  f.association :carrier, :factory => :carrier
end