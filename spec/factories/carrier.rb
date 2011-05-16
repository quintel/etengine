Factory.define :carrier do |f|
  f.name 'carrier_name'
  f.sequence(:carrier_id) {|n| n}
end
