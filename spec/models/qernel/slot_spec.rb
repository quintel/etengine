require 'spec_helper'

module Qernel
  describe Slot do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe "conversion with flexible slots" do
      before do 
        @gql = Scenario.default.gql
        @converter = @gql.future_graph.converter(:converter_fixture_for_slots)
      end
      it "if flexible: true takes the remainder of its siblings conversion" do
        @converter.input(:gas).conversion.should == 0.4
      end

      it "if multiple flexible slots raise error" do
        @converter.input(:electricity).flexible = true
        -> { @converter.input(:gas).conversion.should }.should raise_error
      end

      it "assigns 1.0 if others are nil or empty" do
        @converter.input(:electricity).conversion = nil
        @converter.input(:gas).conversion.should == 1.0
      end

      it "#flexible_conversion returns nil if not flexible: true" do
        @converter.input(:electricity).flexible_conversion.should == nil
      end

      it "if flexible: true and conversion is defined, flexible has no effect" do
        @converter.input(:gas).conversion = 0.111
        @converter.input(:gas).conversion.should == 0.111
      end
    end
  end
end