# frozen_string_literal: true

class Identity::ScenarioPrivacyComponent < ApplicationComponent
  extend Dry::Initializer
  include ButtonHelper

  option :private
end
