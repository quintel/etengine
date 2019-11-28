require 'spec_helper'

describe Scenario do
  before { @scenario = Scenario.new }
  subject { @scenario }

  describe "#default" do
    subject { Scenario.default }

    describe '#area_code' do
      subject { super().area_code }
      it { is_expected.to eq('nl')}
    end

    describe '#user_values' do
      subject { super().user_values }
      it { is_expected.to eq({}) }
    end

    describe '#end_year' do
      subject { super().end_year }
      it { is_expected.to eq(2050) }
    end

    describe '#start_year' do
      let(:scenario) { subject }

      it 'matches the dataset analysis year' do
        expect(scenario.start_year)
          .to eq(Atlas::Dataset.find(:nl).analysis_year)
      end

      describe 'when the dataset does not exist' do
        let(:scenario) do
          described_class.default.tap { |s| s.area_code = 'invalid'}
        end

        it 'returns 2015' do
          expect(scenario.start_year).to eq(2015)
        end
      end
    end

    describe "#years" do
      describe '#years' do
        subject { super().years }
        it { is_expected.to eq(39) }
      end
    end
  end

  describe '#migratable' do
    it 'returns all migratable scenarios from the past month' do
      allow(described_class).to receive(:migratable_since)

      described_class.migratable

      expect(described_class)
        .to have_received(:migratable_since).with(1.month.ago.to_date)
    end
  end

  describe '#migratable_since' do
    subject { described_class.migratable_since(since) }

    let(:since) { 1.month.ago }

    let!(:scenario) do
      FactoryBot.create(
        :scenario,
        user_values: { a: 1 },
        source: 'ETM',
        title: 'Hello'
      )
    end

    context 'with unprotected scenarios' do
      it 'includes recent scenarios' do
        is_expected.to include(scenario)
      end

      it 'includes scenarios with no source' do
        scenario.update_attribute(:source, nil)
        is_expected.to include(scenario)
      end

      it 'includes scenarios with no title' do
        scenario.update_attribute(:title, nil)
        is_expected.to include(scenario)
      end

      it 'omits recent scenarios where title="test"' do
        scenario.update_attribute(:title, 'test')
        is_expected.not_to include(scenario)
      end

      it 'omits recent scenarios where source="Mechanical Turk"' do
        scenario.update_attribute(:source, 'Mechanical Turk')
        is_expected.not_to include(scenario)
      end

      it 'omits scenarios updated prior to the "since" date' do
        scenario.update_attribute(:updated_at, since - 1.hour)
        is_expected.not_to include(scenario)
      end

      it 'omits scenarios with NULL user_values' do
        scenario.update_attribute(:user_values, nil)
        is_expected.not_to include(scenario)
      end

      it 'omits scenarios with empty user_values' do
        scenario.update_attribute(:user_values, {})
        is_expected.not_to include(scenario)
      end
    end

    context 'with protected scenarios' do
      before { scenario.update_attribute(:protected, true) }

      it 'includes recent scenarios' do
        is_expected.to include(scenario)
      end

      it 'includes scenarios with no source' do
        scenario.update_attribute(:source, nil)
        is_expected.to include(scenario)
      end

      it 'includes scenarios with no title' do
        scenario.update_attribute(:title, nil)
        is_expected.to include(scenario)
      end

      it 'omits recent scenarios where title="test"' do
        scenario.update_attribute(:title, 'test')
        is_expected.not_to include(scenario)
      end

      it 'omits recent scenarios where source="Mechanical Turk"' do
        scenario.update_attribute(:source, 'Mechanical Turk')
        is_expected.not_to include(scenario)
      end

      it 'incudes scenarios updated prior to the "since" date' do
        scenario.update_attribute(:updated_at, since - 1.hour)
        is_expected.to include(scenario)
      end

      it 'omits scenarios with NULL user_values' do
        scenario.update_attribute(:user_values, nil)
        is_expected.not_to include(scenario)
      end

      it 'omits scenarios with empty user_values' do
        scenario.update_attribute(:user_values, {})
        is_expected.not_to include(scenario)
      end
    end
  end

  describe "user supplied parameters" do
    it "should not allow a bad area code" do
      s = Scenario.new(:area_code => '{}')
      expect(s).to_not be_valid
      expect(s.errors[:area_code])
    end

    it "should not allow a bad year format" do
      s = Scenario.new(:end_year => 'abc')
      expect(s).to_not be_valid
      expect(s.errors[:end_year])
    end
  end

  describe "#user_values" do
    context ":user_values = YAMLized object (when coming from db)" do
      before {@scenario = Scenario.new(:user_values => {:foo => :bar})}
      it "should unyaml,overwrite and return :user_values" do
        expect(@scenario.user_values).to eq({'foo' => :bar})
        expect(@scenario.user_values[:foo]).to eq(:bar)
      end

    end
    context ":user_values = nil" do
      before {@scenario = Scenario.new(:user_values => nil)}

      describe '#user_values' do
        subject { super().user_values }
        it { is_expected.to eq({}) }
      end
    end
    context ":user_values = obj" do
      before {@scenario = Scenario.new(:user_values => {})}

      describe '#user_values' do
        subject { super().user_values }
        it { is_expected.to eq({}) }
      end
    end
  end

  describe '#input_value' do
    let(:input) { Input.new(key: 'my-input', start_value: 99.0) }

    before { allow(Input).to receive(:all).and_return([input]) }
    before { Rails.cache.clear }

    context 'with a user value present' do
      let(:scenario) do
        FactoryBot.create(:scenario, {
          user_values:     { 'my-input' => 20.0 },
          balanced_values: { 'my-input' => 50.0 }
        })
      end

      it 'returns the user value' do
        expect(scenario.input_value(input)).to eql(20.0)
      end
    end

    context 'with a balanced value present' do
      let(:scenario) do
        FactoryBot.create(:scenario, balanced_values: { 'my-input' => 50.0 })
      end

      it 'returns the balanced value' do
        expect(scenario.input_value(input)).to eql(50.0)
      end
    end

    context 'with no user or balanced value' do
      let(:scenario) { FactoryBot.create(:scenario) }

      it "returns the input's default value" do
        expect(scenario.input_value(input)).to eql(99.0)
      end
    end

    context 'given nil' do
      it 'raises an error' do
        expect { FactoryBot.create(:scenario).input_value(nil) }.
          to raise_error(/nil is not an input/)
      end
    end
  end

  describe "#used_groups_add_up?" do
    before do
      @scenario = Scenario.default
      allow(Input).to receive(:inputs_grouped).and_return({
        'share_group' => [
          double('Input', id: 1, share_group: 'share_group'),
          double('Input', id: 2, share_group: 'share_group'),
          double('Input', id: 3, share_group: 'share_group')
        ],
        'share_group_unused' => [
          double('Input', id: 4, share_group: 'share_group_unused'),
          double('Input', id: 5, share_group: 'share_group_unused')
        ]
      })
    end
    subject { @scenario }

    describe "#used_groups" do
      context "no user_values" do
        describe '#used_groups' do
          subject { super().used_groups }
          it { is_expected.to be_empty }
        end
      end
      context "with 1 user_values" do
        before { @scenario.user_values = {1 => 2}}

        describe '#used_groups' do
          subject { super().used_groups }
          it { is_expected.not_to be_empty }
        end
      end
    end

    describe "#used_groups_add_up?" do
      context "no user_values" do
        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_truthy }
        end
      end

      context "user_values but without groups" do
        before { @scenario.user_values = {10 => 2}}

        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_truthy }
        end
      end

      context "user_values that don't add up to 100" do
        before { @scenario.user_values = {1 => 50}}

        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_falsey }
        end

        describe '#used_groups_not_adding_up' do
          subject { super().used_groups_not_adding_up }

          it 'has 1 item' do
            expect(subject.length).to eq(1)
          end
        end
      end

      context "user_values that add up to 100" do
        before { @scenario.user_values = {1 => 50, 2 => 30, 3 => 20}}

        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_truthy }
        end
      end

      context "with balanced values which add up to 100" do
        before do
          @scenario.user_values     = { 1 => 50}
          @scenario.balanced_values = { 2 => 20, 3 => 30 }
        end

        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_truthy }
        end
      end

      context "with balanced values which do not add up to 100" do
        before do
          @scenario.user_values     = { 1 => 40 }
          @scenario.balanced_values = { 2 => 20, 3 => 30 }
        end

        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_falsey }
        end

        describe '#used_groups_not_adding_up' do
          subject { super().used_groups_not_adding_up }

          it 'has 1 item' do
            expect(subject.length).to eq(1)
          end
        end
      end

      context "with only balanced values which add up to 100" do
        before do
          @scenario.user_values     = {}
          @scenario.balanced_values = { 1 => 50, 2 => 20, 3 => 30 }
        end

        describe '#used_groups_add_up?' do
          subject { super().used_groups_add_up? }
          it { is_expected.to be_truthy }
        end
      end

    end
  end

  describe 'with a preset Preset' do
    let(:preset)   { Preset.get(2999) }
    let(:scenario) { Scenario.new(scenario_id: preset.id) }

    describe '#parent' do
      it 'should retrieve a copy of the parent' do
        expect(scenario.parent).to eq(preset.to_scenario)
      end
    end

    context 'when the preset has a flexibility order' do
      let(:atlas_preset) { Atlas::Preset.find(:with_flexibility_order) }
      let(:preset) { Preset.get(atlas_preset.id) }

      it 'assigns a flexibility order' do
        expect(scenario.flexibility_order).to_not be_nil
      end

      it 'copies the flexibility order attributes' do
        expect(scenario.flexibility_order.order)
          .to eq(atlas_preset.flexibility_order)
      end
    end
  end # with a preset Preset

  describe 'with a preset scenario' do
    let(:preset) do
      FactoryBot.create(:scenario, {
        id:              99999, # Avoid a collision with a preset ID
        user_values:     { 'grouped_input_one' => 1 },
        balanced_values: { 'grouped_input_two' => 2 }
      })
    end

    let(:scenario) do
      Scenario.new(scenario_id: preset.id)
    end

    it 'should retrieve the parent' do
      expect(scenario.parent).to eq(preset)
    end

    it 'should copy the user values' do
      expect(scenario.user_values).to eql(preset.user_values)
    end

    it 'should copy the balanced values' do
      expect(scenario.balanced_values).to eql(preset.balanced_values)
    end

    it 'should copy the scaler attributes' do
      ScenarioScaling.create!(
        scenario:       preset,
        area_attribute: 'number_of_residences',
        value:          1000
      )

      expect(scenario.scaler).to_not be_nil
      expect(scenario.scaler.id).to_not eq(preset.scaler.id)

      expect(scenario.scaler.area_attribute).to eq('number_of_residences')
      expect(scenario.scaler.value).to eq(1000)
      expect(scenario.scaler.scenario).to eq(scenario) # Not `preset`.
    end

    context 'with no preset flexibility order' do
      it 'should create no flexibilty order' do
        expect(scenario[:flexibility_order]).to be_nil
      end
    end

    context 'with a custom imported electricity price curve' do
      before do
        preset.imported_electricity_price_curve.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
          filename: 'price_curve.csv',
          content_type: 'text/csv'
        )
      end

      it 'works' do
        expect(scenario.imported_electricity_price_curve).to be_attached
      end

      it 'creates a new attachment' do
        expect(scenario.imported_electricity_price_curve)
          .not_to eq(preset.imported_electricity_price_curve)
      end

      it 'has the same content as the original' do
        expect(scenario.imported_electricity_price_curve.download)
          .to eq(preset.imported_electricity_price_curve.download)
      end
    end

    context 'with a preset flexibility order' do
      let(:techs) do
        FlexibilityOrder.default_order.shuffle
      end

      let!(:order) do
        FlexibilityOrder.create!(scenario: preset, order: techs)
      end

      it 'copies the flexibility order attributes' do
        expect(scenario.flexibility_order).to_not be_nil
        expect(scenario.flexibility_order.id).to_not eq(preset.flexibility_order.id)

        expect(scenario.flexibility_order.order).to eq(techs)
        expect(scenario.flexibility_order.scenario).to eq(scenario) # Not `preset`.
      end
    end
  end

  describe 'cloning a scaled scenario to an unscaled scenario' do
    let(:preset) do
      FactoryBot.create(:scenario, {
        id:              99999, # Avoid a collision with a preset ID
        user_values:     { 'grouped_input_one' => 2 },
        balanced_values: { 'grouped_input_two' => 8 },

        scaler: ScenarioScaling.create!(
          area_attribute: 'number_of_residences',
          value:          1000
        )
      })
    end

    let(:scenario) do
      scenario = Scenario.new(title: '1')
      scenario.descale     = true
      scenario.scenario_id = preset.id
      scenario.save!

      scenario
    end

    let(:multiplier) { Atlas::Dataset.find(:nl).number_of_residences / 1000 }

    it 'creates the scenario' do
      expect(scenario).to_not be_new_record
    end

    it 'sets no scaler' do
      expect(scenario.scaler).to be_nil
    end

    it 'adjusts the input values to fit the full-size region' do
      expect(scenario.user_values).
        to eq({'grouped_input_one' => 2 * multiplier})
    end

    it 'adjusts the balanced values to fit the full-size region' do
      expect(scenario.balanced_values).
        to eq({'grouped_input_two' => 8 * multiplier})
    end

    context 'with a non-existent input' do
      before do
        preset.user_values['invalid'] = 5.0
        preset.save!
      end

      it 'does not raise an error' do
        expect { scenario }.to_not raise_error
      end

      it 'skips the input' do
        expect(scenario.user_values.keys).to_not include('invalid')
      end
    end
  end

  describe 'dup' do
    let(:scenario) do
      Scenario.create!(
        title:           'Test',
        use_fce:         true,
        end_year:        2030,
        area_code:       'nl',
        user_values:     { 1 => 2, 3 => 4 },
        balanced_values: { 5 => 6 }
      )
    end

    before(:each) do
      scenario.inputs_present
      scenario.inputs_future
      scenario.inputs_before
      scenario.gql
    end

    let(:dup) { scenario.dup }

    it 'clones the end year' do
      expect(dup.end_year).to eql(2030)
    end

    it 'clones the area' do
      expect(dup.area_code).to eql('nl')
    end

    it 'clones the user values' do
      expect(dup.user_values).to eql(scenario.user_values)
    end

    it 'clones balanced values' do
      expect(dup.balanced_values).to eql(scenario.balanced_values)
    end

    it 'clones the FCE status' do
      expect(dup.use_fce).to be_truthy
    end

    it 'does not clone the scenario ID' do
      expect(dup.id).to be_nil
    end

    it 'does not clone inputs_present' do
      expect(dup.inputs_present).to_not equal(scenario.inputs_present)
    end

    it 'preserves inputs_present of the original' do
      old_obj = scenario.inputs_present
      dup
      expect(scenario.inputs_present).to equal(old_obj)
    end

    it 're-generates the same inputs_present as for the original' do
      expect(dup.inputs_present).to eq(scenario.inputs_present)
    end

    it 'does not clone inputs_before' do
      expect(dup.inputs_before).not_to equal(scenario.inputs_before)
    end

    it 'does not clone inputs_future' do
      expect(dup.inputs_future).not_to equal(scenario.inputs_future)
    end
  end

  describe '#user_values_as_yaml=' do
    let(:scenario) { Scenario.new }

    it 'permits an empty string' do
      scenario.user_values_as_yaml = ''
      expect(scenario.user_values).to eq({})
    end

    it 'permits nil' do
      scenario.user_values_as_yaml = nil
      expect(scenario.user_values).to eq({})
    end

    it 'permits a hash' do
      scenario.user_values_as_yaml = "---\na: 1\nb: 2.5"
      expect(scenario.user_values).to eq('a' => 1, 'b' => 2.5)
    end

    it 'permits an indifferent access hash' do
      scenario.user_values_as_yaml = <<-YAML.strip_heredoc
        --- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
        a: 1
        b: 2.8
      YAML

      expect(scenario.user_values).to eq('a' => 1, 'b' => 2.8)
    end

    it 'denies a Set' do
      expect do
        scenario.user_values_as_yaml = "--- !ruby/object:Set\nhash: {}\n"
      end.to raise_error(Psych::DisallowedClass)
    end
  end
end
