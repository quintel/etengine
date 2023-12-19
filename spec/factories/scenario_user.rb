# frozen_string_literal: true

FactoryBot.define do
  factory :scenario_user do
    role_id { User::ROLES.key(:scenario_owner) }
    user
    scenario
  end
end


