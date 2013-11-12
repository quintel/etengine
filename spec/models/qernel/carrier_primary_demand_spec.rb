require 'spec_helper'

describe Qernel::Converter, 'carrier primary demand' do
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
      result = query("V(cpd_mixer, primary_demand_of_natural_gas)")

      # There is a single natural gas source node connected directly to the
      # mixer and it accounts for 50% of the mixer demand.
      expect(result).to eql(0.5)
    end

    it 'is zero when the carrier is not on a parent path' do
      # Network gas is used to the LEFT of the node, but not the right.
      expect(query("V(cpd_mixer, primary_demand_of_network_gas)")).to be_zero
    end

    it 'calculates from a distant source' do
      result = query('V(cpd_mixer, primary_demand_of_greengas)')

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
      expect(query('V(cpd_mixer, primary_demand_of_biogas)')).to eql(0.3125)
    end
  end # called on a "middle" node

  describe 'called on a primary consumption node' do
    it 'calculates from a single source' do
      result = query("V(cpd_sink, primary_demand_of_natural_gas)")

      # There is a single natural gas source node connected directly to the
      # mixer and it accounts for 50% of the mixer demand.
      expect(result).to eql(0.5)
    end

    it 'is zero when the carrier is on a node in the middle' do
      # Natural gas accounts for 100% of the sink node.
      expect(query("V(cpd_sink, primary_demand_of_network_gas)")).to eq(1.0)
    end

    it 'calculates from a distant source' do
      result = query('V(cpd_sink, primary_demand_of_greengas)')

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
      expect(query('V(cpd_sink, primary_demand_of_biogas)')).to eql(0.3125)
    end
  end # called on a "middle" node
end # Qernel::Converter, carrier primary demand
