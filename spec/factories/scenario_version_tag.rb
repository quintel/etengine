# frozen_string_literal: true

FactoryBot.define do
  factory :scenario_version_tag do
    description { 'My scenario version' }
    user
    scenario
  end
end
