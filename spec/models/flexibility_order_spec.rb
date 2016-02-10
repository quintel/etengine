require 'spec_helper'

describe FlexibilityOrder do
  it { should validate_uniqueness_of(:scenario_id) }
end
