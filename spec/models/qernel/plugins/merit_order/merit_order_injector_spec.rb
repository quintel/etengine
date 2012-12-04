require 'spec_helper'

module Qernel::Plugins::MeritOrder
  describe MeritOrderInjector do
    before do
      @graph = double("Graph")
    end

    it "should not run on present graph" do
      @graph.stub(:future?){ false }
      @graph.stub(:use_merit_order_demands?){ true }

      m = MeritOrderInjector.new(@graph)

      m.run
      m.should_not_receive(:calculate_merit_order)
    end

    it "should not run if merit order is disabled" do
      @graph.stub(:future?){ true }
      @graph.stub(:use_merit_order_demands?){ false }

      m = MeritOrderInjector.new(@graph)

      m.should_not_receive(:calculate_merit_order)
      m.run
    end

    context "on a future graph, with MO enabled" do
      before do
        @graph.stub(:future?){ true }
        @graph.stub(:use_merit_order_demands?){ true }

        @converter_api = double("ConverterApi")
        @converter_api.stub(:load_profile_key=){ true }
        @converter_api.stub(:variable_costs_per){ 1 }
        @converter_api.stub(:electricity_output_conversion){ 1 }
        @converter_api.stub(:effective_input_capacity){ 1 }
        @converter_api.stub(:number_of_units){ 1 }
        @converter_api.stub(:availability){ 1 }
        @converter_api.stub(:fixed_costs){ 1 }
        @converter_api.stub(:fixed_operation_and_maintenance_costs_per_year){ 1 }
        @converter_api.stub(:load_profile_key){ :solar_pv }
        @converter_api.stub(:full_load_hours){ :foo }
        @converter_api.stub(:installed_production_capacity_in_mw_electricity){ 123 }

        @converter = double("Converter")
        @converter.stub(:key){ :foo }
        @converter.stub(:converter_api){@converter_api}
        @converter.stub(:output){ 123 }

        @graph.stub(:converter){@converter}
        @mo = MeritOrderInjector.new(@graph)

        @mo.stub(:total_electricity_demand){ 123 }
      end

      it "should get a list of converters from ETSource" do
        @mo.should_receive(:calculate_merit_order)
        @mo.run
      end
    end

  end
end
