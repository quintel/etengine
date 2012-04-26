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

        it 'should use the dataset value', focus: true do
          converter.converter_api.households_supplied_per_unit.should eql(20)
        end
      end # when no dataset value is present
    end # households_supplied_per_unit
  end # Qernel::ConverterApi, helper calculations
end # Qernel
