require 'spec_helper'

describe 'Balancer' do
  let(:inputs)      { FactoryGirl.build_list(:static_input, 3) }
  let(:equilibrium) { 100.0 }

  let(:subordinates) do
    Rails.cache.clear
    Input.stub(:all).and_return(inputs)

    values   = masters.zip(inputs).map { |value, input| [input.key, value] }
    scenario = FactoryGirl.build(:scenario)

    Balancer.new(inputs, equilibrium).balance(scenario, Hash[values])
  end

  # --------------------------------------------------------------------------

  describe 'With start:(100, 0, 0)' do
    before do
      inputs.first.start_value = 100
    end

    context 'and masters:(100->50)' do
      let(:masters) { [ 50 ] }

      it 'should set each subordinate to 25' do
        subordinates.should include(inputs[1].key => 25)
        subordinates.should include(inputs[2].key => 25)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(100->50, 0->15)' do
      let(:masters) { [ 50, 15 ] }

      it 'should set the subordinate to 35' do
        subordinates.should include(inputs[2].key => 35)
      end

      it 'should not change the master values' do
        subordinates.should_not have_key(inputs[0].key)
        subordinates.should_not have_key(inputs[1].key)
      end
    end

    context 'and masters:(100->50, 0->25, 0->25)' do
      let(:masters) { [ 50, 25, 25 ] }

      it 'should have no subordinate values' do
        subordinates.should be_empty
      end
    end

    context 'and masters:(100->110)' do
      let(:masters) { [ 110 ] }

      it 'should raise a CannotBalance error' do
        expect { subordinates }.to \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end

    context 'and masters:(100->-101)' do
      let(:masters) { [ -101 ] }

      it 'should raise a CannotBalance error' do
        expect { subordinates }.to \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end

    context 'and masters:(100->10, 0->20, 0->30)' do
      let(:masters) { [ 10, 20, 30 ] }

      it 'should raise a NoSubordinates error' do
        expect { subordinates }.to \
          raise_error(Balancer::NoSubordinates, /no subordinates/i)
      end
    end

    context 'and masters:()' do
      let(:masters) { [] }

      it 'should have no subordinate values' do
        subordinates.should be_kind_of(Hash)
        subordinates.should be_empty
      end
    end

  end # With start:(100, 0, 0)

  # --------------------------------------------------------------------------

  describe 'With start:(50, 30, 20)' do
    before do
      inputs[0].start_value = 50
      inputs[1].start_value = 30
      inputs[2].start_value = 20
    end

    context 'and masters:(50->70)' do
      let(:masters) { [ 70 ] }

      it 'should set the first subordinate to 20' do
        subordinates.should include(inputs[1].key => 20)
      end

      it 'should set the second subordinate to 10' do
        subordinates.should include(inputs[2].key => 10)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(50->0)' do
      let(:masters) { [ 0 ] }

      it 'should set the first subordinate to 55' do
        subordinates.should include(inputs[1].key => 55)
      end

      it 'should set the second subordinate to 45' do
        subordinates.should include(inputs[2].key => 45)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(50->40, 30->10)' do
      let(:masters) { [ 40, 10 ] }

      it 'should set the subordinate to 50' do
        subordinates.should include(inputs[2].key => 50)
      end

      it 'should not change the master values' do
        subordinates.should_not have_key(inputs[0].key)
        subordinates.should_not have_key(inputs[1].key)
      end
    end
  end # With start:(50, 30, 20)

  # --------------------------------------------------------------------------

  describe 'With min/max(-100/100)' do
    before do
      inputs.each { |input| input.min_value = -100 }
    end

    context 'and masters:(100->-50)' do
      let(:masters) { [ -50 ] }

      it 'should set the subordinates to 75' do
        subordinates.should include(inputs[1].key => 75)
        subordinates.should include(inputs[2].key => 75)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(100->90, 0->40)' do
      let(:masters) { [ 90, 40 ] }

      it 'should set the second subordinate to -30' do
        subordinates.should include(inputs[2].key => -30)
      end

      it 'should not change the master values' do
        subordinates.should_not have_key(inputs[0].key)
        subordinates.should_not have_key(inputs[1].key)
      end
    end

    context 'and masters:(100->0, 0->-1)' do
      let(:masters) { [ 0, -1 ] }

      it 'should raise a CannotBalance error' do
        expect { subordinates }.to \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end
  end

  # --------------------------------------------------------------------------

  describe 'With equilibrium:500, min/max:(0/500), start:(250, 250, 0)' do
    let(:equilibrium) { 500 }

    before do
      inputs[0].start_value = 250
      inputs[1].start_value = 250
      inputs[2].start_value =   0

      inputs.each { |input| input.max_value = 500 }
    end

    context 'and masters:(250->50)' do
      let(:masters) { [ 50 ] }

      it 'should set the first subordinate to 350' do
        subordinates.should include(inputs[1].key => 350)
      end

      it 'should set the second subordinate to 100' do
        subordinates.should include(inputs[2].key => 100)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(250->0, 250->300)' do
      let(:masters) { [ 0, 300 ] }

      it 'should set the subordinate to 200' do
        subordinates.should include(inputs[2].key => 200)
      end

      it 'should not change the master values' do
        subordinates.should_not have_key(inputs[0].key)
        subordinates.should_not have_key(inputs[1].key)
      end
    end
  end # With equilibrium:500, min/max:(0/500), start:(250, 250, 0)

  # --------------------------------------------------------------------------

  describe 'With min/max:(0/100, 0/40, 0/10), start:(100, 0, 0)' do
    before do
      inputs[0].start_value = 100
      inputs[1].max_value   =  40
      inputs[2].max_value   =  10
    end

    context 'and masters:(100->50)' do
      let(:masters) { [ 50 ] }

      it 'should set the first subordinate to 40' do
        subordinates.should include(inputs[1].key => 40)
      end

      it 'should set the second subordinate to 10' do
        subordinates.should include(inputs[2].key => 10)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(100->80)' do
      let(:masters) { [ 80 ] }

      it 'should set the first subordinate to 16' do
        subordinates.should include(inputs[1].key => 16)
      end

      it 'should set the second subordinate to 4' do
        subordinates.should include(inputs[2].key => 4)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end

    context 'and masters:(100->49)' do
      let(:masters) { [ 49 ] }

      it 'should raise a CannotBalance error' do
        expect { subordinates }.to \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end
  end # With min/max:(0/100, 0/50, 0/10), start:(100, 0, 0)

  # --------------------------------------------------------------------------

  # Tests that no floating point precision errors occur.
  describe 'With min/max:(0/0.001), start:(0.0005, 0.0005, 0)' do
    let(:equilibrium) { 0.001 }

    before do
      inputs[0].start_value = 0.0005
      inputs[1].start_value = 0.0005

      inputs.each { |input| input.max_value = 0.001 }
    end

    context 'and masters:(0.0005->0.0004)' do
      let(:masters) { [ 0.0004 ] }

      it 'should set the first subordinate to 0.00055' do
        subordinates.should include(inputs[1].key => 0.00055)
      end

      it 'should set the second subordinate to 0.00005' do
        subordinates.should include(inputs[2].key => 0.00005)
      end

      it 'should not change the master value' do
        subordinates.should_not have_key(inputs[0].key)
      end
    end
  end # With min/max:(0/0.001), start:(0.0005, 0.0005, 0)

  # --------------------------------------------------------------------------

  describe 'With irregular values' do
    let(:inputs)  { FactoryGirl.build_list(:static_input, 5) }

    before do
      inputs[0].start_value = 89.99
      inputs[1].start_value = 0.00001
      inputs[2].start_value = 0.045
      inputs[3].start_value = 10.005
      inputs[4].start_value = 0.04999

      inputs[1].max_value   = 0.000021
    end

    context 'and masters:(89.99->89.889...)' do
      let(:masters) { [ 89.889999999999999999999999 ] }

      it 'should not raise a CannotBalance error' do
        expect { subordinates }.to_not \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end

    context 'and masters:(89.99->89.999...)' do
      let(:masters) { [ 89.99999999999999999999 ] }

      it 'should not raise a CannotBalance error' do
        expect { subordinates }.to_not \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end

    context 'and masters:(89.99->99.0)' do
      let(:masters) { [ 99.0 ] }

      it 'should not raise a CannotBalance error' do
        expect { subordinates }.to_not \
          raise_error(Balancer::CannotBalance, /could not balance/i)
      end
    end
  end # With irregular values.

end # Balancer
