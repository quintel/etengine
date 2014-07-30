require 'spec_helper'

module Qernel::Plugins::MeritOrder
  describe MeritOrderInjector do
    before do
      @graph = double("Graph")
      Rails.cache.clear
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
        @converter_api.stub(:input_capacity){ 1 }
        @converter_api.stub(:number_of_units){ 1 }
        @converter_api.stub(:availability){ 1 }
        @converter_api.stub(:fixed_costs){ 1 }
        @converter_api.stub(:fixed_operation_and_maintenance_costs_per_year){ 1 }
        @converter_api.stub(:load_profile_key){ :solar_pv }
        @converter_api.stub(:full_load_hours){ 365 * 24 }
        @converter_api.stub(:installed_production_capacity_in_mw_electricity){ 123 }

        @converter = double("Converter")
        @converter.stub(:key){ SecureRandom.uuid }
        @converter.stub(:converter_api){ @converter_api }
        @converter.stub(:output){ 123 }

        @graph.stub(:converter){ @converter }
        @graph.stub_chain(:area, :area_code) { :nl }
        @graph.stub_chain(:graph_query, :total_demand_for_electricity) do
          140
        end
        @mo = MeritOrderInjector.new(@graph)
      end

      it "should get a list of converters from ETSource" do
        Etsource::MeritOrder.any_instance.should_receive(:import).once.
          and_return({'dispatchable' => {}, 'volatile' => {}, 'must_run' => {}})
        @mo.run
      end

      it "should calculate values" do
        expect(@mo).to receive(:calculate_merit_order).and_call_original

        @mo.run
      end

      it 'should inject values' do
        expect(@mo).to receive(:calculate_merit_order).and_call_original
        expect(@converter_api).to receive(:[]=).at_least(:once)
        expect(@converter_api).to receive(:demand=).at_least(:once)

        @mo.run
        @mo.inject_values
      end

      it 'should use the merit order data for the graph region' do
        @graph.stub_chain(:area, :area_code) { :eu }

        eu = Atlas::Dataset.find(:eu)
        nl = Atlas::Dataset.find(:nl)

        expect(eu).to receive(:load_profile).at_least(:once).and_call_original
        expect(nl).to_not receive(:load_profile)
        expect(@mo).to receive(:calculate_merit_order).and_call_original

        @mo.run
      end
    end

  end
end
