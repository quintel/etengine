require 'spec_helper'

module Qernel

describe Carrier do
 before do
   @carrier = Carrier.new(1, 'carrier-1', 'Carrier One')
 end


 describe "using graph data" do
   before do
     @dataset = Qernel::Dataset.new(1)
     attributes = {'co2_combustion_per_mj' => 9.6,'co2_transportation_per_mj' => 1.5, 'co2_extraction_per_mj' => 2.5}
     @dataset.<<(@carrier.dataset_key => attributes)
     @carrier.dataset = @dataset
     
     @api_scenario = ApiScenario.create(Scenario.default_attributes.merge(:title => 'foo', :api_session_key => 'foo'))
   end

   pending it "should get co2_combustion_per_mj" do
     @carrier.co2_combustion_per_mj.should be_near(9.6)
   end
   
   pending it "should get co2_transportation_per_mj" do
     @carrier.co2_transportation_per_mj.should be_near(1.5)
   end
   
   pending it "should get co2_extraction_per_mj" do
     @carrier.co2_extraction_per_mj.should be_near(2.5)
   end
   
   context "#co2_per_mj" do
     pending it "should return the co2_combustion_per_mj attr as co2_per_mj when fce not used" do
       get :show, :id => @api_scenario.api_session_key, :use_fce => false       
       @carrier.co2_per_mj.should be_near(9.6)
     end

     pending it "should sum all the co2 attrs when fce is used" do
       get :show, :id => @api_scenario.api_session_key, :use_fce => true
       @carrier.co2_per_mj.should be_near(13.6) 
     end     
   end

 end
end

end

