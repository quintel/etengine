Factory.define :graph do |f|
  f.association :dataset,   :factory => :dataset
  f.association :blueprint, :factory => :blueprint
end