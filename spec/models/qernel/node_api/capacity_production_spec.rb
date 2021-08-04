# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::CapacityProduction do
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

  describe '#coefficient_of_performance' do
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
end
