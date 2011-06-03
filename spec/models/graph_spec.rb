require 'spec_helper'

describe Graph do
  it { should belong_to :blueprint }
  it { should belong_to :dataset }
  
  describe "#to_qernel" do
    it "should return a Qernel::Graph object" do
      d = Factory :dataset
      b = Factory :blueprint
      g = Factory :graph, :blueprint => b, :dataset => d
      g.to_qernel.should be_a(Qernel::Graph)
    end
  end
end

