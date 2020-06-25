# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::CalculationUnits do
  let!(:first_module) do
    Module.new do
      include Qernel::CalculationUnits
      unit_for_calculation :first, 1
    end
  end

  let!(:second_module) do
    other_mod = first_module

    Module.new do
      include Qernel::CalculationUnits
      include other_mod
      unit_for_calculation :second, 2
    end
  end

  describe 'when used on a module' do
    it 'stores values from the module' do
      expect(first_module.unit_for_calculation(:first)).to eq(1)
    end

    it 'does not store values from other modules' do
      expect(first_module.unit_for_calculation(:second)).to be_nil
    end

    it 'does not store values which were not assigned' do
      expect(first_module.unit_for_calculation(:no)).to be_nil
    end
  end

  describe 'when used on a module with an included module' do
    it 'stores values from the module' do
      expect(second_module.unit_for_calculation(:second)).to eq(2)
    end

    it 'stores values from the parent module' do
      expect(second_module.unit_for_calculation(:first)).to eq(1)
    end

    it 'does not store values which were not assigned' do
      expect(second_module.unit_for_calculation(:no)).to be_nil
    end
  end

  describe 'when used on a class which inherits from a two-layer module' do
    let!(:klass) do
      second_mod = second_module

      Class.new do
        include Qernel::CalculationUnits
        include second_mod
        unit_for_calculation :third, 3
      end
    end

    it 'stores values from the class' do
      expect(klass.unit_for_calculation(:third)).to eq(3)
    end

    it 'stores values from the parent module' do
      expect(klass.unit_for_calculation(:first)).to eq(1)
    end

    it 'stores values from the module' do
      expect(klass.unit_for_calculation(:second)).to eq(2)
    end

    it 'does not store values which were not assigned' do
      expect(klass.unit_for_calculation(:no)).to be_nil
    end
  end

  describe 'when used on a class which inherits from a two-layer module and the parent' do
    let!(:klass) do
      first_mod = first_module
      second_mod = second_module

      Class.new do
        include Qernel::CalculationUnits
        include first_mod
        include second_mod
        unit_for_calculation :third, 3
      end
    end

    it 'stores values from the class' do
      expect(klass.unit_for_calculation(:third)).to eq(3)
    end

    it 'stores values from the parent module' do
      expect(klass.unit_for_calculation(:first)).to eq(1)
    end

    it 'stores values from the module' do
      expect(klass.unit_for_calculation(:second)).to eq(2)
    end

    it 'does not store values which were not assigned' do
      expect(klass.unit_for_calculation(:no)).to be_nil
    end
  end

  describe 'when used on a class which inherits a class' do
    let(:first_klass) do
      first_mod = first_module

      Class.new do
        include Qernel::CalculationUnits
        include first_mod
        unit_for_calculation :third, 3
      end
    end

    let(:klass) do
      second_mod = second_module

      Class.new(first_klass) do
        include Qernel::CalculationUnits
        include second_mod
        unit_for_calculation :fourth, 4
      end
    end

    it 'stores values from the class' do
      expect(klass.unit_for_calculation(:fourth)).to eq(4)
    end

    it 'stores values from the parent class' do
      expect(klass.unit_for_calculation(:third)).to eq(3)
    end

    it 'stores values from the parent module' do
      expect(klass.unit_for_calculation(:first)).to eq(1)
    end

    it 'stores values from the module' do
      expect(klass.unit_for_calculation(:second)).to eq(2)
    end

    it 'does not store values which were not assigned', :focus do
      expect(klass.unit_for_calculation(:no)).to be_nil
    end
  end
end
