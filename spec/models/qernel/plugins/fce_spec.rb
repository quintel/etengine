require 'spec_helper'

class DummyGraph
  attr_accessor :use_fce

  def self.set_callback(a, b, c); end

  include Qernel::Plugins::Fce

  def carrier(key)
    @carriers ||= {}
    @carriers[key.to_s] ||= begin
      carrier = Qernel::Carrier.new(key: key)

      # TODO: Should probably turn this into some fixtures.
      carrier.with(co2_per_mj: 25000)

      if key.to_s == 'coal'
        carrier[:fce] = [
          {
            origin_country: 'africa',
            start_value: 50.0,
            co2_conversion_per_mj: 100.0,
            co2_exploration_per_mj: 100.0,
            co2_extraction_per_mj: 100.0,
            co2_treatment_per_mj: 100.0,
            co2_transportation_per_mj: 100.0,
            co2_waste_treatment_per_mj: 100.0
          }, {
            origin_country: 'russia',
            start_value: 50.0,
            co2_conversion_per_mj: 5000.0,
            co2_exploration_per_mj: 5000.0,
            co2_extraction_per_mj: 5000.0,
            co2_treatment_per_mj: 5000.0,
            co2_transportation_per_mj: 5000.0,
            co2_waste_treatment_per_mj: 5000.0
          }
        ]
      elsif key.to_s == 'greengas'
        carrier.dataset_set(:co2_exploration_per_mj, 80.0)
        carrier.dataset_set(:co2_conversion_per_mj, 2.0)
      end

      carrier
    end
  end
end

describe 'Qernel::Plugins::Fce' do
  before(:each) do
    @graph = DummyGraph.new
  end

  describe 'with FCE enabled' do
    before(:each) do
      @graph.use_fce = true
      @graph.calculate_fce
    end

    it 'should calculate FCE if there are FCE profiles on the carrier' do
      coal = @graph.carrier(:coal)
      coal[:co2_per_mj].should eq(15300)
    end

    it 'should calculate FCE if there are no profiles on the carrier' do
      greengas = @graph.carrier(:greengas)
      greengas[:co2_per_mj].should eq(82)
    end
  end

  describe 'without FCE enabled' do
    before(:each) do
      @graph.use_fce = false
      @graph.calculate_fce
    end

    it 'should only calculate conversion if there are FCE profiles on the carrier' do
      coal = @graph.carrier(:coal)
      coal[:co2_per_mj].should eq(2550)
    end

    it 'should only calculate conversion if there are no profiles on the carrier' do
      greengas = @graph.carrier(:greengas)
      greengas[:co2_per_mj].should eq(2)
    end
  end
end
