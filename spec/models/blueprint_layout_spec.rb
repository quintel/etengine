require 'spec_helper'

describe BlueprintLayout do
  it { should validate_presence_of :key }
  it { should have_many :converter_positions }
end

