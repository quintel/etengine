require 'spec_helper'

describe Qernel::Node, 'carrier dependent supply' do
  before :all do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:gql) { Scenario.default.gql }

  def query(string)
    gql.query_future(string)
  end

  describe 'called on a "middle" node' do
    it 'calculates from a single source' do
      result = query("V(cpd_mixer, dependent_supply_of_carrier(natural_gas))")

      # There is a single natural gas source node connected directly to the
      # mixer and it accounts for 50% of the mixer demand.
      expect(result).to eql(0.5)
    end

    it 'is zero when the carrier is not on a parent path' do
      # Network gas is used to the LEFT of the node, but not the right.
      expect(query("V(cpd_mixer, dependent_supply_of_carrier(network_gas))")).to be_zero
    end

    it 'calculates from a distant source' do
      result = query('V(cpd_mixer, dependent_supply_of_carrier(greengas))')

      # Biogas is 50% of the green gas source. Green gas provides 50% of the
      # 1.0 demand on the mixer, BUT one of the green gas nodes has 20% loss.
      # Finally, 50% of that green gas comes from biogas and is therefore not
      # included.
      #
      # Therefore, green gas share is ((1.0 * 0.5) / 0.8) * 0.5
      expect(result).to eq(((1.0 * 0.5) / 0.8) * 0.5)
    end

    it 'calculates from a single leaf node' do
      # Biogas accounts for 50% of biogas production, which in turn mixes into
      # the mixer node.
      expect(query('V(cpd_mixer, dependent_supply_of_carrier(biogas))')).to eql(0.3125)
    end
  end # called on a "middle" node

  describe 'called on a primary consumption node' do
    it 'calculates from a single source' do
      result = query("V(cpd_sink, dependent_supply_of_carrier(natural_gas))")

      # There is a single natural gas source node connected directly to the
      # mixer and it accounts for 50% of the mixer demand.
      expect(result).to eql(0.5)
    end

    it 'is zero when the carrier is on a node in the middle' do
      # Natural gas accounts for 100% of the sink node.
      expect(query("V(cpd_sink, dependent_supply_of_carrier(network_gas))")).to eq(1.0)
    end

    it 'calculates from a distant source' do
      result = query('V(cpd_sink, dependent_supply_of_carrier(greengas))')

      # Biogas is 50% of the green gas source. Green gas provides 50% of the
      # 1.0 demand on the mixer, BUT one of the green gas nodes has 20% loss.
      # Finally, 50% of that green gas comes from biogas and is therefore not
      # included.
      #
      # Therefore, green gas share is ((1.0 * 0.5) / 0.8) * 0.5
      expect(result).to eq(((1.0 * 0.5) / 0.8) * 0.5)
    end

    it 'calculates from a single leaf node' do
      # Biogas accounts for 50% of biogas production, which in turn mixes into
      # the mixer node.
      expect(query('V(cpd_sink, dependent_supply_of_carrier(biogas))')).to eql(0.3125)
    end
  end # called on a "middle" node

  describe 'called with multiple carriers' do
    let(:carriers) { %w( natural_gas network_gas greengas biogas ) }

    let(:result) do
      query("V(cpd_sink, dependent_supply_of_carriers(#{ carriers.join(', ') }))")
    end

    it 'returns a numeric' do
      expect(result).to be_a(Numeric)
    end

    it 'prevents double-counting demand' do
      doubled = carriers.sum do |carrier_key|
        query("V(cpd_sink, dependent_supply_of_carrier(#{ carrier_key }))")
      end

      expect(result < doubled).to be_truthy
    end
  end # called with multiple carriers
end # Qernel::Node, carrier dependent supply
