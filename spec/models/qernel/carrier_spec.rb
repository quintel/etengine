require 'spec_helper'

module Qernel

describe Carrier do
  describe "#method_missing" do
    it "should create dynamic carrier key boolean methods" do
      expect(Carrier.new(:key => 'foo').foo?).to be_truthy
      expect(Carrier.new(:key => 'baz').foo?).to be_falsey
    end
  end

 before do
   @carrier = Carrier.new(key: 'carrier-1', id: 1)
 end



 describe "using graph data" do
   before do
     @dataset = Qernel::Dataset.new(1)
     attributes = {'co2_combustion_per_mj' => 9.6,'co2_transportation_per_mj' => 1.5, 'co2_extraction_per_mj' => 2.5}
     @dataset.<<(@carrier.dataset_key => attributes)
     @carrier.dataset = @dataset

     @api_scenario = Scenario.create(Scenario.default_attributes.merge(:title => 'foo'))
   end

   skip it "should get co2_combustion_per_mj" do
     expect(@carrier.co2_combustion_per_mj).to be_near(9.6)
   end

   skip it "should get co2_transportation_per_mj" do
     expect(@carrier.co2_transportation_per_mj).to be_near(1.5)
   end

   skip it "should get co2_extraction_per_mj" do
     expect(@carrier.co2_extraction_per_mj).to be_near(2.5)
   end

   context "#co2_per_mj" do
     skip it "should return the co2_combustion_per_mj attr as co2_per_mj when fce not used" do
       get :show, params: { :id => @api_scenario.id, :use_fce => false }
       expect(@carrier.co2_per_mj).to be_near(9.6)
     end
   end

 end
end

end

