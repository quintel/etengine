require 'spec_helper'

describe Gquery do
  describe "#new" do
    it "should remove whitespace from key" do
      gquery = Gquery.create(:key => " foo \t ", :query => "SUM(1,1)")
      gquery.key.should == 'foo'
    end
  end

end
