require 'spec_helper'

describe ScenarioScaling do
  let(:scaling) do
    ScenarioScaling.new(
      area_attribute: :number_of_residences,
      value:          500_000,
      scenario:       FactoryGirl.build(:scenario)
    )
  end

  let(:divisor) { Atlas::Dataset.find(:nl).number_of_residences / 500_000 }

  # ----------------------------------------------------------------------------

  it { should validate_presence_of(:area_attribute) }
  # it { should validate_inclusion_of(:area_attribute).in_array(%w(number_of_residences)) }

  it { should validate_presence_of(:value) }
  it { should validate_numericality_of(:value) }

  describe '.scale_input?' do
    it 'is true when the input has no unit' do
      expect(ScenarioScaling.scale_input?(Input.new(unit: nil))).to be_true
    end

    it 'is true when the input unit is km' do
      expect(ScenarioScaling.scale_input?(Input.new(unit: 'km'))).to be_true
    end

    it 'is false when the input unit is %' do
      expect(ScenarioScaling.scale_input?(Input.new(unit: '%'))).to be_false
    end

    it 'is false when the input unit is x' do
      expect(ScenarioScaling.scale_input?(Input.new(unit: 'x'))).to be_false
    end
  end # .scale_input?

  describe '#scale' do
    it 'scales a number to fit the area' do
      expect(scaling.scale(1.0)).to eq(1.0 / divisor)
    end
  end # #scale

  describe '#scale_dataset!' do
    let(:dataset) { Qernel::Dataset.new }
    let(:graph)   { dataset.data[:graph] }

    it 'scales node "preset_demand"' do
      graph[:a] = { preset_demand: 100 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:preset_demand]).to eq(100 / divisor)
    end

    it 'scales node "demand_expected_value"' do
      graph[:a] = { demand_expected_value: 100 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:demand_expected_value]).to eq(100 / divisor)
    end

    it 'scales node "max_demand"' do
      graph[:a] = { max_demand: 100 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:max_demand]).to eq(100 / divisor)
    end

    it 'scales node "number_of_units"' do
      graph[:a] = { number_of_units: 100 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:number_of_units]).to eq(100 / divisor)
    end

    it 'scales edge "demand"' do
      graph[:a] = { demand: 100 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:demand]).to eq(100 / divisor)
    end

    it 'scales edge "max_demand" when numeric' do
      graph[:a] = { max_demand: 100 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:max_demand]).to eq(100 / divisor)
    end

    it 'ignores edge "max_demand" when non-numeric' do
      graph[:a] = { max_demand: :recursive }
      expect { scaling.scale_dataset!(dataset) }.to_not raise_error

      expect(graph[:a][:max_demand]).to eq(:recursive)
    end

    it 'does not scale edge "share" normally' do
      graph[:a] = { share: 0.5 }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:share]).to eq(0.5)
    end

    it 'scales edge "share" for constant edges' do
      graph[:a] = { share: 100, type: :constant }
      scaling.scale_dataset!(dataset)

      expect(graph[:a][:share]).to eq(100 / divisor)
    end
  end # #scale_dataset!

  describe 'scale_area_dataset!' do
    let(:original) { Atlas::Dataset.find(:nl).attributes }
    let(:area)     { dataset.data[:area][:area_data] }

    let(:dataset) do
      Qernel::Dataset.new.tap { |d| d.data[:area][:area_data] = original.dup }
    end

    ScenarioScaling::SCALEABLE_AREA_ATTRS.each do |key|
      it "scales #{ key }" do
        if original[key]
          scaling.scale_dataset!(dataset)
          expect(area[key]).to be_within(1e-5).of(original[key] / divisor)
        end
      end
    end

    (Atlas::Dataset.attribute_set.map(&:name) -
     ScenarioScaling::SCALEABLE_AREA_ATTRS).each do |key|
      it "does not scale #{ key }" do
        scaling.scale_dataset!(dataset)
        expect(area[key]).to eq(original[key])
      end
    end

  end # #scale_area_dataset!
end # ScenarioScaling
