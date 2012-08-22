require 'spec_helper'

describe Input do
  let(:scenario) { Scenario.new(area_code: 'nl', end_year: 2050) }
  let(:gql)      { scenario.gql }
  before         { Input.stub(:all).and_return([input]) }
  before         { Rails.cache.clear }

  context 'when the input has no GQL start, minimum, or maximum' do
    let(:input) do
      Factory.build(:input, {
        key:         'test-input',
        start_value:  5,
        min_value:    2,
        max_value:   10
      })
    end

    describe 'min_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.min_value_for(gql).should eql(2)
      end

      it 'should return the value when given Scenario' do
        input.min_value_for(scenario).should eql(2)
      end
    end

    describe 'max_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.max_value_for(gql).should eql(10)
      end

      it 'should return the value when given Scenario' do
        input.max_value_for(scenario).should eql(10)
      end
    end

    describe 'start_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.start_value_for(gql).should eql(5)
      end

      it 'should return the value when given Scenario' do
        input.start_value_for(scenario).should eql(5)
      end
    end

    describe 'label_value_for' do
      it 'should return nil when given Gql::Gql' do
        input.label_value_for(gql).should be_nil
      end

      it 'should return nil when given Scenario' do
        input.label_value_for(scenario).should be_nil
      end
    end

    describe 'full_label_for' do
      it 'should return nil when given Gql::Gql' do
        input.full_label_for(gql).should be_nil
      end

      it 'should return nil when given Scenario' do
        input.full_label_for(scenario).should be_nil
      end
    end
  end # when the input has no GQL start, minimum, or maximum

  context 'when the input has area-dependent minima and maxima' do
    let(:input) do
      Factory.build(:input, {
        key:         'test-input',
        start_value:  5,
        min_value:    2,
        max_value:   10
      })
    end

    before do
      area_input_values = YAML.dump(
        input.id => { 'min' => 1_000, 'max' => 5_000, 'disabled' => true })

      # Bad, bad, bad! I hate stubbing; it's so fragile.
      Etsource::Loader.instance.
        should_receive(:area_attributes).any_number_of_times.
        with(scenario.area_code).
        and_return(:input_values => area_input_values)
    end

    describe 'min_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.min_value_for(gql).should eql(1_000)
      end

      it 'should return the value when given a Scenario' do
        input.min_value_for(scenario).should eql(1_000)
      end
    end

    describe 'max_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.max_value_for(gql).should eql(5_000)
      end

      it 'should return the value when given a Scenario' do
        input.max_value_for(scenario).should eql(5_000)
      end
    end

    describe 'disabled_in_current_area?' do
      it 'should return true when given Gql::Gql' do
        input.disabled_in_current_area?(gql).should be_true
      end

      it 'should return true when given a Scenario' do
        input.disabled_in_current_area?(scenario).should be_true
      end
    end
  end # when the input has area-dependent minima and maxima

  context 'when the input has GQL start, minimum, and maximum' do
    let(:input) do
      Factory.build(:input, {
        key:             'test-input',
        start_value:      5,
        start_value_gql: 'present:(5 * 5)',
        min_value:        2,
        min_value_gql:   'present:(2 * 5)',
        max_value:        10,
        max_value_gql:   'present:(10 * 5)',
        label:           '%',
        label_query:     'present:(50 * 10)'
      })
    end

    describe 'min_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.min_value_for(gql).should eql(10)
      end

      it 'should return the value when given Scenario' do
        input.min_value_for(scenario).should eql(10)
      end
    end

    describe 'max_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.max_value_for(gql).should eql(50)
      end

      it 'should return the value when given Scenario' do
        input.max_value_for(scenario).should eql(50)
      end
    end

    describe 'start_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.start_value_for(gql).should eql(25)
      end

      it 'should return the value when given Scenario' do
        input.start_value_for(scenario).should eql(25)
      end
    end

    describe 'label_value_for' do
      it 'should return the value when given Gql::Gql' do
        input.label_value_for(gql).to_f.should eql(500.0)
      end

      it 'should return the value when given Scenario' do
        input.label_value_for(scenario).to_f.should eql(500.0)
      end
    end

    describe 'full_label_for' do
      it 'should return the value when given Gql::Gql' do
        input.full_label_for(gql).should eql('500.0 %')
      end

      it 'should return the value when given Scenario' do
        input.full_label_for(scenario).should eql('500.0 %')
      end
    end
  end # when the input has GQL start, minimum, and maximum

  context 'when the input returns a non-numeric value' do
    let(:input) do
      input = Factory.build(:input, {
        key:         'test-input',
        start_value:  5,
        min_value:    2,
        max_value:    10,
      })

      input.stub(:start_value_for).and_return([1, 2, 3])
      input
    end

    it 'should cache an error' do
      data = Input.cache.read(scenario, input)
      data.should have_key(:error)
      data[:error].should eql('Non-numeric GQL value')
    end

    it 'should disable the input' do
      data = Input.cache.read(scenario, input)
      data.should have_key(:disabled)
      data[:disabled].should be_true
    end
  end

end
