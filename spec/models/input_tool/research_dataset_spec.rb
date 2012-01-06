require 'spec_helper'

module InputTool

  describe ResearchDataset do
    describe "#get" do
      before do
        @values = {'foo' => {'bar' => '1.0'}}
        @research_dataset = ResearchDataset.new(@values)
      end

      specify { @research_dataset.values.should == @values }
      
      it "should return " do 
        @research_dataset.get().should == nil
      end

      it "should return the (raw) sub-hash" do 
        @research_dataset.get('foo').should == {'bar' => '1.0'}
      end

      it "should work with strings and symbols" do
        @research_dataset.get('foo', 'bar').should == 1.0 
        @research_dataset.get(:foo, :bar).should == 1.0
      end

      it "should try to convert the last value to a float" do
        @research_dataset.get(:foo, :bar).should == 1.0
      end

      it "should return nil as :default if not set" do
        @research_dataset.get(:zyx).should == nil
      end

      it "should not try to convert the last value to if it doesnt respond to #to_f" do
        ResearchDataset.new({:foo => :bar}).get(:foo).should == :bar
      end
      
      it "should return arrays (that are not #blank?)" do
        ResearchDataset.new({:foo => [1]}).get(:foo).should == [1]
      end

      it "should return the :default if result is #blank?" do
        ResearchDataset.new({:foo => []}).get(:foo, default: 2.0 ).should == 2.0
        ResearchDataset.new({:foo => ""}).get(:foo, default: 2.0 ).should == 2.0
        ResearchDataset.new({:foo => {}}).get(:foo, default: 2.0 ).should == 2.0
      end

      it "should return nil as :default if not set" do
        ResearchDataset.new({:foo => nil}).get(:foo).should == nil
      end
    end

    describe "#keys_that_contain" do
      before do
        @research_dataset = ResearchDataset.new({:hh => {
          :sector => {
            :coal  => {:needle => 1.0}, 
            :water => {:needle => 1.0}, 
            :gas   => {:something => {:needle => 3.0}}
          }
        }})
      end

      it "should find the keys that have hashes including x as key." do
        # note that it does not include 'gas'
        # note that it converts symbols to strings, not quite sure why
        @research_dataset.keys_that_contain(:hh, :sector, :needle).should == ['coal', 'water']
      end

    end
  end

end
