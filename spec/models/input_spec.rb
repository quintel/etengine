require 'spec_helper'

describe Input do
  let(:scenario) { FactoryBot.build(:scenario, end_year: 2050) }
  let(:gql)      { scenario.gql }
  before         { allow(Input).to receive(:all).and_return([input]) }
  before         { Rails.cache.clear }

  context 'when the input has no GQL start, minimum, or maximum' do
    let(:input) do
      FactoryBot.build(:input, {
        key:         'test-input',
        start_value:  5,
        min_value:    2,
        max_value:    10,
        step_value:   1.0
      })
    end

    # Unscaled scenario
    context 'with an unscaled scenario' do
      describe 'min_value_for' do
        it 'should return 2 when given Gql::Gql' do
          expect(input.min_value_for(gql)).to eq(2)
        end

        it 'should return the value when given Scenario' do
          expect(input.min_value_for(scenario)).to eq(2)
        end
      end

      describe 'max_value_for' do
        it 'should return the value when given Gql::Gql' do
          expect(input.max_value_for(gql)).to eq(10)
        end

        it 'should return the value when given Scenario' do
          expect(input.max_value_for(scenario)).to eq(10)
        end
      end

      describe 'start_value_for' do
        it 'should return the value when given Gql::Gql' do
          expect(input.start_value_for(gql)).to eq(5)
        end

        it 'should return the value when given Scenario' do
          expect(input.start_value_for(scenario)).to eq(5)
        end
      end

      describe 'step value' do
        it 'should return the value when given Scenario' do
          expect(input.step_value).to eq(1.0)
        end
      end
    end

    # Scaled scenario to 10.000 households
    context 'with a scenario scaled to 10.000 households' do
      before do
        scenario.save!
        scenario.create_scaler!(
          area_attribute: 'number_of_residences',
          value: 10000
        )
      end

      describe 'min_value_for' do
        it 'should return the value when given Scenario' do
          expect(input.min_value_for(scenario)).
            to be_within(1e-9).of(2.0 / 7210388.0 * 10000)
        end
      end

      describe 'max_value_for' do
        it 'should return the value when given Scenario' do
          expect(input.max_value_for(scenario)).to eq(10.0 / 7210388.0 * 10000)
        end
      end

      describe 'start_value_for' do
        it 'should return the value when given Scenario' do
          expect(input.start_value_for(scenario)).to eq(5.0 / 7210388.0 * 10000)
        end
      end

      describe 'step value' do
        it 'should return the value when given Scenario' do
          expect(
            input.cache_for(scenario).read(scenario, input)[:step]
          ).to eq(0.001)
        end
      end
    end

    # Scenario with derived dataset to 1000 households
    context 'with a derived dataset scaled to 1000 households' do
      before { scenario.update_attribute(:area_code, :ameland) }

      describe 'min_value_for' do
        it 'should return the value when given Scenario' do
          expect(input.min_value_for(scenario)).
            to be_within(1e-9).of(2.0 / 7449298.0 * 1000)
        end
      end

      describe 'max_value_for' do
        it 'should return scaled value when given Scenario' do
          expect(input.max_value_for(scenario)).
            to be_within(1e-9).of(10.0 / 7449298.0 * 1000)
        end
      end

      describe 'start_value_for' do
        it 'should return scaled value when given Scenario' do
          expect(input.start_value_for(scenario)).to eql(5.0 / 7449298.0 * 1000)
        end
      end

      describe 'step value' do
        it 'should return the value when given Scenario' do
          expect(
            input.cache_for(scenario).read(scenario, input)[:step]
          ).to eq(0.0001)
        end
      end
    end

    # Scenario with derived dataset to 1000 households
    # .. and scaled to 100 households
    context 'with a derived dataset scaled to 1000 households scaled to 100 households' do
      before {
        scenario.update_attribute(:area_code, 'ameland')
        scenario.create_scaler(
          area_attribute: 'number_of_residences',
          value: 100
        )
      }

      describe 'min_value_for' do
        it 'should return the value when given Scenario' do
          input.key = "marked"
          expect(input.min_value_for(scenario)).
            to be_within(1e-9).of(2.0 / 7449298.0 * 100)
        end
      end

      describe 'max_value_for' do
        it 'should return scaled value when given Scenario' do
          expect(input.max_value_for(scenario)).
            to be_within(1e-9).of(10.0 / 7449298.0 * 100)
        end
      end

      describe 'start_value_for' do
        it 'should return scaled value when given Scenario' do
          expect(input.start_value_for(scenario)).
            to eq(5.0 / 7449298.0 * 100)
        end
      end

      describe 'step value' do
        it 'should return the value when given Scenario' do
          expect(
            input.cache_for(scenario).read(scenario, input)[:step]
          ).to eq(0.00001)
        end
      end
    end

    describe 'label_value_for' do
      it 'should return nil when given Gql::Gql' do
        expect(input.label_value_for(gql)).to be_nil
      end

      it 'should return nil when given Scenario' do
        expect(input.label_value_for(scenario)).to be_nil
      end
    end

    describe 'full_label_for' do
      it 'should return nil when given Gql::Gql' do
        expect(input.full_label_for(gql)).to be_nil
      end

      it 'should return nil when given Scenario' do
        expect(input.full_label_for(scenario)).to be_nil
      end
    end
  end # when the input has no GQL start, minimum, or maximum

  context 'when the input has GQL start, minimum, and maximum' do
    let(:input) do
      FactoryBot.build(:input, {
        key:             'test-input',
        start_value:      5,
        start_value_gql: 'present:(5 * 5)',
        min_value:        2,
        min_value_gql:   'present:(2 * 5)',
        max_value:        10,
        max_value_gql:   'present:(10 * 5)',
        label:           '%',
        label_query:     'present:(50.0 * 10)'
      })
    end

    describe 'min_value_for' do
      it 'should return the value when given Gql::Gql' do
        expect(input.min_value_for(gql)).to eql(10)
      end

      it 'should return the value when given Scenario' do
        expect(input.min_value_for(scenario)).to eql(10)
      end
    end

    describe 'max_value_for' do
      it 'should return the value when given Gql::Gql' do
        expect(input.max_value_for(gql)).to eql(50)
      end

      it 'should return the value when given Scenario' do
        expect(input.max_value_for(scenario)).to eql(50)
      end
    end

    describe 'start_value_for' do
      it 'should return the value when given Gql::Gql' do
        expect(input.start_value_for(gql)).to eql(25)
      end

      it 'should return the value when given Scenario' do
        expect(input.start_value_for(scenario)).to eql(25)
      end
    end

    describe 'label_value_for' do
      it 'should return the value when given Gql::Gql' do
        expect(input.label_value_for(gql)).to eql(500.0)
      end

      it 'should return the value when given Scenario' do
        expect(input.label_value_for(scenario)).to eql(500.0)
      end
    end

    describe 'full_label_for' do
      it 'should return the value when given Gql::Gql' do
        expect(input.full_label_for(gql)).to eql('500.0 %')
      end

      it 'should return the value when given Scenario' do
        expect(input.full_label_for(scenario)).to eql('500.0 %')
      end
    end
  end # when the input has GQL start, minimum, and maximum

  context 'when the input returns NaN' do
    let(:input) do
      FactoryBot.build(:input, {
        key:             'test-input',
        start_value_gql: 'present:0.0 / 0',
        min_value_gql:   'present:0.0 / 0',
        max_value_gql:   'present:0.0 / 0'
      })
    end

    it 'coerces the min value to nil' do
      expect(input.min_value_for(gql)).to be_nil
    end

    it 'coerces the max value to nil' do
      expect(input.max_value_for(gql)).to be_nil
    end

    it 'coerces the start value to nil' do
      expect(input.start_value_for(gql)).to be_nil
    end
  end

  describe '#clamp' do
    context 'with a fixed min of 5 and max of 10' do
      let(:input) { described_class.new(min_value: 5, max_value: 10, start_value: 5) }

      it 'clamps 0 to 5' do
        expect(input.clamp(scenario, 0)).to eq(5)
      end

      it 'clamps 5 to 5' do
        expect(input.clamp(scenario, 5)).to eq(5)
      end

      it 'clamps 7 to 7' do
        expect(input.clamp(scenario, 7)).to eq(7)
      end

      it 'clamps 10 to 10' do
        expect(input.clamp(scenario, 10)).to eq(10)
      end

      it 'clamps 11 to 10' do
        expect(input.clamp(scenario, 11)).to eq(10)
      end

      it 'clamps nil to nil' do
        expect(input.clamp(scenario, nil)).to be_nil
      end

      it 'clamps "invalid" to "invalid"' do
        expect(input.clamp(scenario, 'invalid')).to eq('invalid')
      end
    end

    context 'with a calculated min of 10 and max of 20' do
      let(:input) do
        described_class.new(
          min_value_gql: 'present:5*2',
          max_value_gql: 'present:5*4',
          start_value: 10
        )
      end

      it 'clamps 0 to 10' do
        expect(input.clamp(scenario, 0)).to eq(10)
      end

      it 'clamps 10 to 10' do
        expect(input.clamp(scenario, 10)).to eq(10)
      end

      it 'clamps 15 to 15' do
        expect(input.clamp(scenario, 15)).to eq(15)
      end

      it 'clamps 20 to 20' do
        expect(input.clamp(scenario, 20)).to eq(20)
      end

      it 'clamps 21 to 20' do
        expect(input.clamp(scenario, 21)).to eq(20)
      end

      it 'clamps nil to nil' do
        expect(input.clamp(scenario, nil)).to be_nil
      end

      it 'clamps "invalid" to "invalid"' do
        expect(input.clamp(scenario, 'invalid')).to eq('invalid')
      end
    end

    context 'with an invalid min and max of 20' do
      let(:input) do
        described_class.new(
          min_value_gql: 'present:0.0/0',
          max_value_gql: 'present:5*4',
          start_value: 10
        )
      end

      it 'clamps 0 to nil' do
        expect(input.clamp(scenario, 0)).to be_nil
      end

      it 'clamps 21 to nil' do
        expect(input.clamp(scenario, 21)).to be_nil
      end
    end

    context 'with a min of 5 and invalid max' do
      let(:input) do
        described_class.new(
          min_value_gql: 'present:5',
          max_value_gql: 'present:0.0/0',
          start_value: 10
        )
      end

      it 'clamps 0 to nil' do
        expect(input.clamp(scenario, 0)).to be_nil
      end

      it 'clamps 10 to nil' do
        expect(input.clamp(scenario, 10)).to be_nil
      end
    end
  end

  context 'when the input returns a non-numeric value' do
    let(:input) do
      input = FactoryBot.build(:input, {
        key:         'test-input',
        start_value:  5,
        min_value:    2,
        max_value:    10,
      })

      allow(input).to receive(:start_value_for).and_return([1, 2, 3])
      input
    end

    it 'should cache an error' do
      data = Input.cache.read(scenario, input)
      expect(data).to have_key(:error)
      expect(data[:error]).to eql('Non-numeric GQL value: default')
    end

    it 'should disable the input' do
      data = Input.cache.read(scenario, input)
      expect(data).to have_key(:disabled)
      expect(data[:disabled]).to be_truthy
    end
  end

  context 'when the input have nil GQL start, minimum, and maximum' do
    let(:input) do
      FactoryBot.build(:input, {
        key:             'test-input',
        start_value:      nil,
        start_value_gql: 'present:nil',
        min_value:        nil,
        min_value_gql:   'present:nil',
        max_value:        nil,
        max_value_gql:   'present:nil',
        label_query:     'present:nil'
      })
    end

    describe 'min_value_for' do
      it 'should raise an error when given Gql::Gql' do
        expect { input.min_value_for(gql) }.
          to raise_error(/returned nil/)
      end

      it 'should return the value when given Scenario' do
        expect { input.min_value_for(scenario) }.
          to raise_error(/returned nil/)
      end
    end

    describe 'max_value_for' do
      it 'should return the value when given Gql::Gql' do
        expect { input.max_value_for(gql) }.
          to raise_error(/returned nil/)
      end

      it 'should return the value when given Scenario' do
        expect { input.max_value_for(scenario) }.
          to raise_error(/returned nil/)
      end
    end

    describe 'start_value_for' do
      context 'and the input has no minimum value value' do
        it 'should return the value when given Gql::Gql' do
          expect { input.start_value_for(gql) }.
            to raise_error(/returned nil/)
        end

        it 'should return the value when given Scenario' do
          expect { input.start_value_for(scenario) }.
            to raise_error(/returned nil/)
        end
      end

      context 'and the input has a minimum value' do
        before do
          input.min_value_gql = 'present:5.0'
          input.max_value_gql = 'present:8.0'
        end

        it 'should return the value when given Gql::Gql' do
          expect(input.start_value_for(gql)).to eql(5.0)
        end

        it 'should return the value when given Scenario' do
          expect(input.start_value_for(scenario)).to eql(5.0)
        end
      end
    end

    describe 'label_value_for' do
      it 'should return the value when given Gql::Gql' do
        expect(input.label_value_for(gql)).to be_nil
      end

      it 'should return the value when given Scenario' do
        input.min_value_gql = 'present:5.0'
        input.max_value_gql = 'present:8.0'

        expect(input.label_value_for(scenario)).to be_nil
      end
    end
  end # when the input have nil GQL start, minimum, and maximum
end
