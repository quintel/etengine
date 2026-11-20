# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::InstalledCapacity do
  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:plant, demand: 100, typical_input_capacity: 2.0, number_of_units: 10.0)
      builder.add(:sink, demand: 50)
      builder.add(:loss, demand: 50)
      builder.connect(:fuel, :plant, :natural_gas)
      builder.connect(:plant, :sink, :electricity)
      builder.connect(:plant, :loss, :loss)
    end
  end

  let(:api) { builder.to_qernel.node(:plant).node_api }

  it 'defines a method per carrier and direction' do
    expect(Qernel::NodeApi::Base.public_method_defined?(:steam_hot_water_input_installed_capacity))
      .to be(true)
  end

  it 'uses the capacity injected by the participant' do
    api.dataset_set(:electricity_output_installed_capacity, 12.0)
    expect(api.electricity_output_installed_capacity).to eq(12.0)
  end

  it 'uses an injected capacity of 0' do
    api.dataset_set(:electricity_output_installed_capacity, 0.0)
    expect(api.electricity_output_installed_capacity).to eq(0.0)
  end

  it 'falls back to typical input capacity x conversion x number of units' do
    # 2.0 MW x 0.5 x 10 units
    expect(api.electricity_output_installed_capacity).to eq(10.0)
  end

  it 'falls back to the peak of the curve without typical input capacity' do
    api.dataset_set(:typical_input_capacity, 0.0)
    api.dataset_set(:electricity_output_curve, [1.0, 7.0, 3.0])

    expect(api.electricity_output_installed_capacity).to eq(7.0)
  end

  it 'is 0 without a slot of the carrier and without curve' do
    expect(api.hydrogen_output_installed_capacity).to eq(0.0)
  end
end
