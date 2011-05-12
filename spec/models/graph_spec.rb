require 'spec_helper'

describe Graph do
  it { should belong_to :blueprint }
  it { should belong_to :dataset }
  
  describe "#to_qernel" do
    it "should return a Qernel::Graph object" do
      pending "the method fails without proper blueprint and dataset"
    end
  end
end
