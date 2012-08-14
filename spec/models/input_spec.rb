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
  end # when the input has no GQL start, minimum, or maximum

  context 'when the input has GQL start, minimum, and maximum' do
    let(:input) do
      Factory.build(:input, {
        key:             'test-input',
        start_value:      5,
        start_value_gql: 'present:(5 * 5)',
        min_value:        2,
        min_value_gql:   'present:(2 * 5)',
        max_value:        10,
        max_value_gql:   'present:(10 * 5)'
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
