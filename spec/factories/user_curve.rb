FactoryBot.define do
  factory :user_curve do
    association :scenario
    key { "interconnector_1_price_curve" }
    curve { Merit::Curve.new([1.0] * 8760) }
  end
end
