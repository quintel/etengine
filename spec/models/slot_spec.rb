require 'spec_helper'

describe Slot do
  it { should validate_presence_of :carrier }
  it { should validate_presence_of :blueprint }
  it { should validate_presence_of :converter }
end
