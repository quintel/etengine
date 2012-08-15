require 'spec_helper'

module Qernel

  describe Qernel::ConverterApi, 'cost calculations' do

    before :each do
      @c = Qernel::Converter.new(id:1)
    end

    describe '#average_cost_per_year' do

      it "should calculate correctly when numbers are given" do
        @c.with total_real_costs: 3000, lifetime: 30
        @c.converter_api.average_cost_per_year.should == 100
      end

      it "should return a fraction when numbers are small" do
        @c.with total_real_costs: 1, lifetime: 10
        @c.converter_api.average_cost_per_year.should == 0.1
      end

      it "should return zero when total_real_costs is missing" do
        @c.with total_real_costs: nil, lifetime: 30
        @c.converter_api.average_cost_per_year.should == 0
      end

      it "should return zero when lifetime is missing" do
        @c.with total_real_costs: 3000, lifetime: nil
        @c.converter_api.average_cost_per_year.should == 0
      end

      it "should return zero when lifetime is 0" do
        @c.with total_real_costs: 3000, lifetime: 0
        @c.converter_api.average_cost_per_year.should == 0
      end

      it "should return zero when total_real_costs is 0" do
        @c.with total_real_costs: 0, lifetime: 30
        @c.converter_api.average_cost_per_year.should == 0
      end
    end

  end

end
