require 'spec_helper'

module Qernel
  describe Qernel::ConverterApi, 'helper calculations' do
    let(:graph) do
      layout = <<-LAYOUT.strip_heredoc
        foo: network(100) == s(0.25) ==> supply_one
      LAYOUT

      GraphParser.new(layout).build
    end # graph

    let(:converter) { graph.converters.first }

    describe 'households_supplied_per_unit' do
      context 'when no dataset value is present' do
        it 'should default to 1' do
          converter.converter_api.households_supplied_per_unit.should eql(1.0)
        end
      end # when no dataset value is present

      context 'when an explicit dataset value is present' do
        before { converter.dataset_set(:households_supplied_per_unit, 20) }

        it 'should use the dataset value' do
          converter.converter_api.households_supplied_per_unit.should eql(20)
        end
      end # when no dataset value is present
    end # households_supplied_per_unit

    describe 'number_of_units' do

      context 'when a value is set' do
        before { converter.converter_api.number_of_units = 4.0 }

        it 'returns the value' do
          expect(converter.converter_api.number_of_units).to eq(4.0)
        end
      end

      context 'when the value is set to nil' do
        before do
          converter.converter_api.number_of_units = nil

          converter.converter_api.dataset_set(:input_capacity, 2.0)
          converter.converter_api.dataset_set(:full_load_hours, 1.0 / 3600)
          converter.converter_api.dataset_set(:demand, 4.0)
        end

        # This is the default case for most converters, which do not have a
        # value provided in ETSource.
        it 'computes the value' do
          expect(converter.converter_api.number_of_units).to eq(2.0)
        end
      end
    end
  end # Qernel::ConverterApi, helper calculations
end # Qernel
