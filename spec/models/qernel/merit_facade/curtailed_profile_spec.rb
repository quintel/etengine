# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::MeritFacade::CurtailedProfile do
  let(:source) { [0.1, 0.2, 0.3, 0.4] }
  let(:demand) { 100.0 }
  let(:curtailed) { described_class.new(source, curtailment) }

  context 'with no curtailment' do
    let(:curtailment) { 0.0 }

    it 'does not curtail the useable profile' do
      expect(curtailed.useable_profile).to eq(source)
    end

    it 'has an empty curtailment curve' do
      expect(curtailed.curtailment_curve(demand)).to eq([0, 0, 0, 0])
    end
  end

  context 'with curtailment of 0.25' do
    let(:curtailment) { 0.25 }

    it 'curtails the useable profile by 25%' do
      expect(curtailed.useable_profile.map { |v| v.round(1) })
        .to eq([0.1, 0.2, 0.3, 0.3])
    end

    it 'sets curtailed values in the curtailment curve' do
      # Total demand is 100. Original profile value in index 3 is 0.4 which
      # means uncurtailed produces 40 demand. The curtailed profile is 0.3,
      # therefore 10 is curtailed.
      expect(curtailed.curtailment_curve(demand).map { |v| v.round(1) })
        .to eq([0, 0, 0, 10])
    end
  end

  context 'with curtailment of 0.25 and a profile with zeros' do
    let(:source) { [0.1, 0.0, 0.3, 0.4] }
    let(:curtailment) { 0.25 }

    it 'curtails the useable profile by 25%' do
      expect(curtailed.useable_profile.map { |v| v.round(1) })
        .to eq([0.1, 0.0, 0.3, 0.3])
    end

    it 'sets curtailed values in the curtailment curve' do
      expect(curtailed.curtailment_curve(demand).map { |v| v.round(1) })
        .to eq([0, 0, 0, 10])
    end
  end

  context 'with curtailment of 1.0' do
    let(:curtailment) { 1.0 }

    it 'has an empty useable profile' do
      expect(curtailed.useable_profile).to eq([0, 0, 0, 0])
    end

    it 'sets curtailed values in the curtailment curve' do
      expect(curtailed.curtailment_curve(demand)).to eq([10, 20, 30, 40])
    end
  end
end
