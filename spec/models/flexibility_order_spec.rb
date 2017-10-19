require 'spec_helper'

describe FlexibilityOrder do
  it { is_expected.to validate_uniqueness_of(:scenario_id) }
end
