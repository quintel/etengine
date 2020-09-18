# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::RecursiveFactor::BioEmissions do
  # Create a graph:
  #
  #            <- [CCS Plant #1] <- [Torrefied Biomass]
  # [Terminus] <- [CCS Plant #2] <- [Green Gas]
  #            <- [Normal Plant] <- [Coal]
  #
  # All three suppliers have 50 demand. 100% of torrefied biomass is converted to CO2 and 100% is
  # captured on [CCS Plant 1]. 50% of green gas is converted to CO2, and 50% is captured on
  # [CCS Plant 2]. Coal produces no capturable CO2.
  let(:terminus)     { Qernel::Node.new(key: :terminus, graph_name: nil).with(demand: 150.0) }
  let(:ccs_plant_1)  { Qernel::Node.new(key: :ccs_plant_1, graph_name: nil).with(demand: 50.0) }
  let(:ccs_plant_2)  { Qernel::Node.new(key: :ccs_plant_2, graph_name: nil).with(demand: 50.0) }
  let(:normal_plant) { Qernel::Node.new(key: :normal_plant, graph_name: nil).with(demand: 50.0) }
  let(:biomass)      { Qernel::Node.new(key: :biomass, graph_name: nil).with(demand: 50.0) }
  let(:greengas)     { Qernel::Node.new(key: :greengas, graph_name: nil).with(demand: 50.0) }
  let(:coal)         { Qernel::Node.new(key: :coal, graph_name: nil).with(demand: 50.0) }

  let(:electricity_carrier) { Qernel::Carrier.new(key: :electricity).with({}) }
  let(:biomass_carrier) { Qernel::Carrier.new(key: :torrefied_biomass_pellets).with({}) }
  let(:greengas_carrier) { Qernel::Carrier.new(key: :greengas).with({}) }
  let(:coal_carrier) { Qernel::Carrier.new(key: :coal).with({}) }

  def create_edge(left, right, carrier, demand)
    left.add_slot(Qernel::Slot.new(nil, left, carrier, :input).with(conversion: 1.0))
    right.add_slot(Qernel::Slot.new(nil, right, carrier, :output).with(conversion: 1.0))

    edge = Qernel::Edge.new(
      "#{left.key} <- #{right.key} @ #{carrier.key}", left, right, carrier, :flexible, true
    )

    edge.with(value: demand)
  end

  before do
    create_edge(terminus, ccs_plant_1, electricity_carrier, 50.0)
    create_edge(terminus, ccs_plant_2, electricity_carrier, 50.0)
    create_edge(terminus, normal_plant, electricity_carrier, 50.0)

    create_edge(ccs_plant_1, biomass, biomass_carrier, 50.0)
    create_edge(ccs_plant_2, greengas, greengas_carrier, 50.0)
    create_edge(normal_plant, coal, coal_carrier, 50.0)

    biomass_carrier.with(potential_co2_conversion_per_mj: 1.0)
    greengas_carrier.with(potential_co2_conversion_per_mj: 0.5)

    ccs_plant_1.with(ccs_plant_1.dataset_attributes.merge(ccs_capture_rate: 1.0))
    ccs_plant_2.with(ccs_plant_2.dataset_attributes.merge(ccs_capture_rate: 0.5))
  end

  context 'when the CCS plants have capture' do
    it 'captures 50 on CCS Plant #1' do
      expect(ccs_plant_1.query.captured_bio_emissions).to eq(50)
    end

    it 'captures 12.5 on CCS Plant #2' do
      expect(ccs_plant_2.query.captured_bio_emissions).to eq(12.5)
    end

    it 'captures nothing on Normal Plant' do
      expect(normal_plant.query.captured_bio_emissions).to eq(0)
    end

    it 'captures nothing on Terminus' do
      expect(terminus.query.captured_bio_emissions).to eq(0)
    end

    it 'Terminus inherits 62.5 captured CO2' do
      expect(terminus.query.inherited_captured_bio_emissions).to eq(62.5)
    end
  end

  context 'when CCS plant 1 has no capture' do
    before do
      ccs_plant_1.with(ccs_plant_1.dataset_attributes.merge(ccs_capture_rate: 0.0))
    end

    it 'captures nothing on CCS Plant #1' do
      expect(ccs_plant_1.query.captured_bio_emissions).to eq(0)
    end

    it 'Terminus inherits 12.5 captured CO2' do
      expect(terminus.query.inherited_captured_bio_emissions).to eq(12.5)
    end
  end

  context 'when CCS plant 1 has nil capture' do
    before do
      ccs_plant_1.with(ccs_plant_1.dataset_attributes.merge(ccs_capture_rate: nil))
    end

    it 'captures nothing on CCS Plant #1' do
      expect(ccs_plant_1.query.captured_bio_emissions).to eq(0)
    end

    it 'Terminus inherits 12.5 captured CO2' do
      expect(terminus.query.inherited_captured_bio_emissions).to eq(12.5)
    end
  end

  context 'when the normal plant has capture' do
    before do
      normal_plant.with(normal_plant.dataset_attributes.merge(ccs_capture_rate: 1.0))
    end

    it 'captures nothing on the Normal Plant' do
      expect(normal_plant.query.captured_bio_emissions).to eq(0)
    end

    it 'Terminus inherits 62.5 captured CO2' do
      expect(terminus.query.inherited_captured_bio_emissions).to eq(62.5)
    end
  end
end
