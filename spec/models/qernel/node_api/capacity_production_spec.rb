# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::CapacityProduction do
  describe '#coefficient_of_performance' do
    let(:builder) do
      TestGraphBuilder.new.tap do |builder|
        builder.add(:cop, demand: 1)
        builder.add(:electricity, demand: 0)
        builder.add(:gas, demand: 0)
        builder.add(:ambient_heat, demand: 0)

        builder.connect(:ambient_heat, :cop, :ambient_heat)
      end
    end

    let(:node) { builder.to_qernel.node(:cop) }

    describe 'with no Fever config, elec: 0.8, ambient_heat:0.2' do
      before do
        builder.connect(:electricity, :cop, :electricity)

        builder.node(:electricity).set(:demand, 0.8)
        builder.node(:ambient_heat).set(:demand, 0.2)
      end

      it 'has a coefficient_of_performance of 1.25' do
        expect(node).to have_query_value(:coefficient_of_performance, 1.25)
      end
    end

    describe 'with no Fever config, elec: 0.4, ambient_heat:0.6' do
      before do
        builder.connect(:electricity, :cop, :electricity)

        builder.node(:electricity).set(:demand, 0.4)
        builder.node(:ambient_heat).set(:demand, 0.6)
      end

      it 'has a coefficient_of_performance of 2.5' do
        expect(node).to have_query_value(:coefficient_of_performance, 2.5)
      end
    end

    describe 'with no Fever config, elec: 0.0, ambient_heat:1.0' do
      before do
        builder.connect(:electricity, :cop, :electricity)
        builder.node(:ambient_heat).set(:demand, 1)
      end

      it 'has a coefficient_of_performance of 1.0' do
        expect(node).to have_query_value(:coefficient_of_performance, 1.0)
      end
    end

    describe 'with no Fever efficiency config, elec: 0.8, ambient_heat:0.2' do
      before do
        builder.connect(
          :electricity,
          :cop,
          :electricity,
        )

        builder.node(:cop).set(:fever, Atlas::NodeAttributes::Fever.new)
        builder.node(:electricity).set(:demand, 0.8)
        builder.node(:ambient_heat).set(:demand, 0.2)
      end

      it 'has a coefficient_of_performance of 1.25' do
        expect(node).to have_query_value(:coefficient_of_performance, 1.25)
      end
    end

    describe 'with a Fever efficiency config, elec:0.4, ambient_heat:0.6' do
      before do
        builder.connect(
          :electricity,
          :cop,
          :electricity,
        )

        builder.node(:cop).set(:fever, Atlas::NodeAttributes::Fever.new(
          efficiency_based_on: :electricity,
          efficiency_balanced_with: :ambient_heat
        ))

        builder.node(:electricity).set(:demand, 0.4)
        builder.node(:ambient_heat).set(:demand, 0.6)
      end

      it 'has a coefficient_of_performance of 2.5' do
        expect(node).to have_query_value(:coefficient_of_performance, 2.5)
      end
    end

    describe 'with a Fever efficiency config, elec:0.0, ambient_heat:0.0' do
      before do
        builder.connect(:electricity, :cop, :electricity)

        builder.node(:cop).set(:fever, Atlas::NodeAttributes::Fever.new(
          efficiency_based_on: :electricity,
          efficiency_balanced_with: :ambient_heat
        ))

        builder.node(:electricity).set(:demand, 0.0)
        builder.node(:ambient_heat).set(:demand, 0.0)
      end

      it 'has a coefficient_of_performance of 1.0' do
        expect(node).to have_query_value(:coefficient_of_performance, 1.0)
      end
    end

    describe 'with a Fever efficiency config, elec:1.0, ambient_heat:0.0' do
      before do
        builder.connect(:electricity, :cop, :electricity)

        builder.node(:cop).set(:fever, Atlas::NodeAttributes::Fever.new(
          efficiency_based_on: :electricity,
          efficiency_balanced_with: :ambient_heat
        ))

        builder.node(:electricity).set(:demand, 1)
      end

      it 'has a coefficient_of_performance of 1.0' do
        expect(node).to have_query_value(:coefficient_of_performance, 1.0)
      end
    end

    describe 'with a Fever efficiency config, gas:0.3, elec: 0.2, ambient_heat:0.5' do
      before do
        builder.connect(:electricity, :cop, :electricity)
        builder.connect(:gas, :cop, :gas)

        builder.node(:cop).set(:fever, Atlas::NodeAttributes::Fever.new(
          efficiency_based_on: :electricity,
          efficiency_balanced_with: :ambient_heat
        ))

        builder.node(:electricity).set(:demand, 0.2)
        builder.node(:gas).set(:demand, 0.3)
        builder.node(:ambient_heat).set(:demand, 0.5)
      end

      it 'has a coefficient_of_performance of 3.5' do
        expect(node).to have_query_value(:coefficient_of_performance, 3.5)
      end
    end

    describe 'with a Fever efficiency config, gas:1.0, elec: 0.0, ambient_heat:0.0' do
      before do
        builder.connect(:electricity, :cop, :electricity)
        builder.connect(:gas, :cop, :gas)

        builder.node(:cop).set(:fever, Atlas::NodeAttributes::Fever.new(
          efficiency_based_on: :electricity,
          efficiency_balanced_with: :ambient_heat
        ))

        builder.node(:gas).set(:demand, 1)
      end

      it 'has a coefficient_of_performance of 1.0' do
        expect(node).to have_query_value(:coefficient_of_performance, 1.0)
      end
    end
  end

  describe '#electricity_output_capacity' do
    let(:builder) do
      TestGraphBuilder.new.tap do |builder|
        builder.add(:node, demand: 100)
        builder.add(:consumer_1, demand: 70)
        builder.add(:consumer_2, demand: 30)

        builder.connect(:node, :consumer_1, carrier)
        builder.connect(:node, :consumer_2, :__ignored__)
      end
    end

    let(:node) { builder.to_qernel.node(:node) }

    context 'when the node has an explicit electricity_output_capacity' do
      let(:carrier) { :electricity }

      before do
        builder.node(:node).set(:typical_input_capacity, 20)
        builder.node(:node).set(:electricity_output_capacity, 100.0)
      end

      it 'uses the explicit capacity' do
        expect(node.query.electricity_output_capacity).to eq(100)
      end
    end

    context 'when the node has a typical_input_capacity and electricity output' do
      let(:carrier) { :electricity }

      before { builder.node(:node).set(:typical_input_capacity, 20) }

      it 'calculates an electricity output capacity' do
        expect(node.query.electricity_output_capacity).to eq(14)
      end
    end

    context 'when the node has no typical_input_capacity and electricity output' do
      let(:carrier) { :electricity }

      before { builder.node(:node).set(:typical_input_capacity, nil) }

      it 'calculates an electricity output capacity' do
        expect(node.query.electricity_output_capacity).to eq(0.0)
      end
    end

    context 'when the node has a typical_input_capacity and no electricity output' do
      let(:carrier) { :__not_electricity__ }

      before { builder.node(:node).set(:typical_input_capacity, 20) }

      it 'calculates an electricity output capacity' do
        expect(node.query.electricity_output_capacity).to eq(0.0)
      end
    end

    context 'when the node has no typical_input_capacity and no electricity output' do
      let(:carrier) { :__not_electricity__ }

      before { builder.node(:node).set(:typical_input_capacity, nil) }

      it 'calculates an electricity output capacity' do
        expect(node.query.electricity_output_capacity).to eq(0.0)
      end
    end
  end

  describe '#heat_output_capacity' do
    let(:builder) do
      TestGraphBuilder.new.tap do |builder|
        builder.add(:node, demand: 100)
        builder.add(:consumer_1, demand: 70)
        builder.add(:consumer_2, demand: 30)

        builder.connect(:node, :consumer_1, carrier)
        builder.connect(:node, :consumer_2, :__ignored__)
      end
    end

    let(:node) { builder.to_qernel.node(:node) }

    context 'when the node has an explicit electricity_output_capacity' do
      let(:carrier) { :steam_hot_water }

      before do
        builder.node(:node).set(:typical_input_capacity, 20)
        builder.node(:node).set(:heat_output_capacity, 100.0)
      end

      it 'uses the explicit capacity' do
        expect(node.query.heat_output_capacity).to eq(100)
      end
    end

    context 'when the node has a typical_input_capacity and steam_hot_water output' do
      let(:carrier) { :steam_hot_water }

      before { builder.node(:node).set(:typical_input_capacity, 20) }

      it 'calculates a heat output capacity' do
        expect(node.query.heat_output_capacity).to eq(14)
      end
    end

    context 'when the node has a typical_input_capacity and useable_heat output' do
      let(:carrier) { :useable_heat }

      before { builder.node(:node).set(:typical_input_capacity, 20) }

      it 'calculates a heat output capacity' do
        expect(node.query.heat_output_capacity).to eq(14)
      end
    end

    context 'when the node has no typical_input_capacity and useable_heat output' do
      let(:carrier) { :useable_heat }

      before { builder.node(:node).set(:typical_input_capacity, nil) }

      it 'calculates a heat output capacity' do
        expect(node.query.heat_output_capacity).to eq(0.0)
      end
    end

    context 'when the node has a typical_input_capacity and no heat output' do
      let(:carrier) { :__not_heat__ }

      before { builder.node(:node).set(:typical_input_capacity, 20) }

      it 'calculates a heat output capacity' do
        expect(node.query.heat_output_capacity).to eq(0.0)
      end
    end

    context 'when the node has no typical_input_capacity and no heat output' do
      let(:carrier) { :__not_heat__ }

      before { builder.node(:node).set(:typical_input_capacity, nil) }

      it 'calculates a heat output capacity' do
        expect(node.query.heat_output_capacity).to eq(0.0)
      end
    end
  end
end
