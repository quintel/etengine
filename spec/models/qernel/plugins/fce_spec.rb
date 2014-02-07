require 'spec_helper'

describe Qernel::Plugins::FCE::FCECalculator do
  describe 'with FCE enabled' do
    let(:calculator) { Qernel::Plugins::FCE::FCECalculator.new(:nl, true) }

    it 'calculates FCE profiles for carriers which have one' do
      expect(calculator.calculate_carrier(:coal).keys).
        to eq(Qernel::Carrier::CO2_FCE_COMPONENTS + [:co2_per_mj])
    end

    it 'prefers user-provided shares' do
      expect { calculator.update(:coal, :north_america, 0.9) }.
        to change { calculator.calculate_carrier(:coal)[:co2_per_mj] }
    end

    it 'does not calculate FCE profiles for carriers without one' do
      expect(calculator.calculate_carrier(:lng).keys).to eq([:co2_per_mj])
    end
  end # with FCE enabled

  describe 'in an area with no FCE profiles, and FCE enabled' do
    let(:calculator) { Qernel::Plugins::FCE::FCECalculator.new(:de, true) }

    it 'only calculates the co2_per_mj attribute, even with a profile' do
      expect(calculator.calculate_carrier(:coal).keys).to eq([:co2_per_mj])
    end

    it 'only calculates the co2_per_mj attribute for carriers with no profile' do
      expect(calculator.calculate_carrier(:lng).keys).to eq([:co2_per_mj])
    end
  end # in an area with no FCE profiles, and FCE enabled

  describe 'with FCE disabled' do
    let(:calculator) { Qernel::Plugins::FCE::FCECalculator.new(:nl, false) }

    it 'only calculates two attributes when the carrier has a profile' do
      expect(calculator.calculate_carrier(:coal).keys).
        to eq([:co2_conversion_per_mj, :co2_per_mj])
    end

    it 'only calculates the co2_per_mj attribute for carriers with no profile' do
      expect(calculator.calculate_carrier(:lng).keys).to eq([:co2_per_mj])
    end
  end # with FCE disabled
end # Qernel::FCE::FCECalculator
