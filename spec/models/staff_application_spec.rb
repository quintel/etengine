# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StaffApplication, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:application).dependent(:destroy) }
end
