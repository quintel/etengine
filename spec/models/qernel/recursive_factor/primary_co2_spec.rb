# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::RecursiveFactor::PrimaryCo2 do
  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:left)
      builder.add(:middle)

      builder.add(
        :right,
        demand: 100,
        groups: %i[primary_energy_demand],
        sustainability_share: 0.25
      )

      builder.connect(:right, :middle, :natural_gas, type: :share)
      builder.connect(:middle, :left, :natural_gas, type: :share)

      builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.5)
    end
  end

  let(:graph) { builder.to_qernel }

  context 'when all shares and conversions are 1.0' do
    describe 'the left node' do
      subject { graph.node(:left) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the right node' do
      subject { graph.node(:right) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the middle node conversions natural_gas=2.0' do
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 2.0)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the middle node has converions natural_gas=0.5' do
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.5)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it { is_expected.to have_query_value(:primary_co2_emission, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 12.5) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 37.5) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the middle node has outputs natural_gas=0.6 and electricity=0.6' do
    # When the sum of output conversions exceed 1.0, the conversion is normalized so that it
    # represents a percentage of the total (two outputs with conversion of 0.6 result in effective
    # conversions of 0.5 each).
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.6)
      builder.node(:middle).slots.out.add(:electricity, share: 0.6)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it { is_expected.to have_query_value(:primary_co2_emission, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 12.5) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 37.5) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the middle node has inputs natural_gas=0.6 and electricity=0.4' do
    # The left and middle nodes now have demand of 100 / 0.75 = 125
    before do
      builder.node(:middle).slots.in(:natural_gas).set(:share, 0.8)
      builder.node(:middle).slots.in.add(:electricity, share: 0.2)

      builder.add(:elec, groups: %i[primary_energy_demand], sustainability_share: 0.1)
      builder.connect(:elec, :middle, :electricity)

      builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.25)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it do
        expect(subject).to have_query_value(
          :primary_co2_emission,
          100 * 0.5 + # From natural_gas
            25 * 0.25 # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :primary_demand_of_sustainable,
          100 * 0.25 + # From natural_gas
            25 * 0.1   # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :primary_demand_of_fossil,
          100 * 0.75 + # From natural_gas
            25 * 0.9   # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :sustainability_share,
          0.25 * 0.8 + # From natural_gas
            0.1 * 0.2  # From electricity
        )
      end
    end
  end

  context 'when the middle node has inputs natural_gas=0.8 and electricity=0.8' do
    # "left" and "middle" have a demand of 125, while "right" and "elec" each have 100.
    before do
      builder.node(:middle).slots.in(:natural_gas).set(:share, 0.8)
      builder.node(:middle).slots.in.add(:electricity, share: 0.8)

      builder.add(:elec, groups: %i[primary_energy_demand], sustainability_share: 0.1)
      builder.connect(:elec, :middle, :electricity)

      builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.25)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it do
        expect(subject).to have_query_value(
          :primary_co2_emission,
          100 * 0.5 +  # From natural_gas
            100 * 0.25 # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :primary_demand_of_sustainable,
          100 * 0.25 + # From natural_gas
            100 * 0.1  # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :primary_demand_of_fossil,
          100 * 0.75 + # From natural_gas
            100 * 0.9  # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :sustainability_share,
          0.25 * 0.5 + # From natural_gas
            0.1 * 0.5  # From electricity
        )
      end
    end

    context 'when sustainability shares are 0.75' do
      subject { graph.node(:left) }

      before do
        builder.node(:right).set(:sustainability_share, 0.75)
        builder.node(:elec).set(:sustainability_share, 0.75)
      end

      it do
        expect(subject).to have_query_value(:primary_demand_of_sustainable, 150)
      end

      it do
        expect(subject).to have_query_value(:primary_demand_of_fossil, 50)
      end

      it do
        expect(subject).to have_query_value(:sustainability_share, 0.75)
      end
    end
  end

  context 'when the middle node has inputs natural_gas=0.5' do
    # "left" and "middle" have demand of 200, while "right" has 100.
    before do
      builder.node(:middle).slots.in(:natural_gas).set(:share, 0.5)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the middle node has inputs natural_gas=0.4 and electricity=0.4' do
    # "left" and "middle" have a demand of 250, while "right" and "elec" each have 100.
    before do
      builder.node(:middle).slots.in(:natural_gas).set(:share, 0.4)
      builder.node(:middle).slots.in.add(:electricity, share: 0.4)

      builder.add(:elec, groups: %i[primary_energy_demand], sustainability_share: 0.1)
      builder.connect(:elec, :middle, :electricity)

      builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.25)
    end

    describe 'the left node' do
      subject { graph.node(:left) }

      it do
        expect(subject).to have_query_value(
          :primary_co2_emission,
          100 * 0.5 +  # From natural_gas
            100 * 0.25 # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :primary_demand_of_sustainable,
          100 * 0.25 + # From natural_gas
            100 * 0.1  # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :primary_demand_of_fossil,
          100 * 0.75 + # From natural_gas
            100 * 0.9  # From electricity
        )
      end

      it do
        expect(subject).to have_query_value(
          :sustainability_share,
          0.25 * 0.5 + # From natural_gas
            0.1 * 0.5  # From electricity
        )
      end
    end
  end

  context 'when the right node has outputs natural_gas=2.0' do
    before do
      builder.node(:right).slots.out(:natural_gas).set(:share, 2.0)
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the right node' do
      subject { graph.node(:right) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the right node has outputs natural_gas=0.6 and electricity=0.6' do
    # These examples should adjust the values returned by recursive factor methods so that the
    # demand remains 100% that of the node, not 120%.
    before do
      builder.node(:right).slots.out(:natural_gas).set(:share, 0.6)
      builder.node(:right).slots.out.add(:electricity, share: 0.6)
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 12.5) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 37.5) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the right node' do
      subject { graph.node(:right) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end

  context 'when the right node has two natural_gas output edges with shares 0.5' do
    before do
      builder.add(:middle_sibling)
      builder.connect(:right, :middle_sibling, :natural_gas, parent_share: 0.5)
    end

    describe 'the middle node' do
      subject { graph.node(:middle) }

      it { is_expected.to have_query_value(:primary_co2_emission, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 12.5) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 37.5) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end

    describe 'the right node' do
      subject { graph.node(:right) }

      it { is_expected.to have_query_value(:primary_co2_emission, 50) }
      it { is_expected.to have_query_value(:primary_demand_of_sustainable, 25) }
      it { is_expected.to have_query_value(:primary_demand_of_fossil, 75) }
      it { is_expected.to have_query_value(:sustainability_share, 0.25) }
    end
  end
end
