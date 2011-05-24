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

# == Schema Information
#
# Table name: graphs
#
#  id           :integer(4)      not null, primary key
#  blueprint_id :integer(4)
#  dataset_id   :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

