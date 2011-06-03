require 'spec_helper'

describe BlueprintModel do
  it { should have_many :blueprints }
  it { should validate_presence_of :title}
end
