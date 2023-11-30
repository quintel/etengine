require 'spec_helper'

describe Scenario do
  before { @scenario = Scenario.new }
  subject { @scenario }

  describe '.find_for_calculation' do
    context 'when the scenario exists' do
      it 'returns the scenario' do
        scenario = FactoryBot.create(:scenario)
        expect(described_class.find_for_calculation(scenario.id)).to eq(scenario)
      end
    end

    context 'when the scenario does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.find_for_calculation(-1) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the scenario ID is out-of-range' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.find_for_calculation(1 << 31) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

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

      context 'when it not provided' do
        it 'has an error' do
          scenario = described_class.default(end_year: nil)
          scenario.valid?

          expect(scenario.errors[:end_year]).to include("can't be blank")
        end
      end

      context 'given a float' do
        it 'has an error' do
          scenario = described_class.default(end_year: 2019.5)
          scenario.valid?

          expect(scenario.errors[:end_year]).to include("must be an integer")
        end
      end

      context 'when it is greater than the start year' do
        it 'has no error' do
          scenario = described_class.default(end_year: 2020)
          allow(scenario).to receive(:start_year).and_return(2019)

          scenario.valid?

          expect(scenario.errors[:end_year]).to be_empty
        end
      end

      context 'when it is equal to the start year' do
        it 'has an error' do
          scenario = described_class.default(end_year: 2019)
          allow(scenario).to receive(:start_year).and_return(2019)

          scenario.valid?

          expect(scenario.errors[:end_year]).to include('must be greater than 2019')
        end
      end
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

        it 'returns 2019' do
          expect(scenario.start_year).to eq(2019)
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
      )
    end

    context 'with a writeable scenarios' do
      it 'includes recent scenarios' do
        is_expected.to include(scenario)
      end

      it 'includes scenarios with no source' do
        scenario.update_attribute(:source, nil)
        is_expected.to include(scenario)
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

    context 'with a keep_compatible scenario' do
      before { scenario.update(keep_compatible: true) }

      it 'includes recent scenarios' do
        is_expected.to include(scenario)
      end

      it 'includes scenarios with no source' do
        scenario.update_attribute(:source, nil)
        is_expected.to include(scenario)
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

  describe "#coupled?" do
    subject { @scenario.coupled? }

    before do
      @scenario = Scenario.default
      allow(Input).to receive(:coupling_sliders_keys).and_return(
        ['coupled_slider_1']
      )
    end

    context 'when no coupled input is set' do
      it { is_expected.to be_falsey }
    end

    context 'when a coupled input is set' do
      before do
        @scenario.user_values = { coupled_slider_1: 1 }
      end

      it { is_expected.to be_truthy }
    end

    context 'when a coupled input is part of balanced values' do
      before do
        @scenario.balanced_values = { coupled_slider_1: 1 }
      end

      it { is_expected.to be_truthy }
    end
  end

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
        area_attribute: 'present_number_of_residences',
        value:          1000
      )

      expect(scenario.scaler).to_not be_nil
      expect(scenario.scaler.id).to_not eq(preset.scaler.id)

      expect(scenario.scaler.area_attribute).to eq('present_number_of_residences')
      expect(scenario.scaler.value).to eq(1000)
      expect(scenario.scaler.scenario).to eq(scenario) # Not `preset`.
    end

    context 'with no preset heat network order' do
      it 'should create no heat network order' do
        expect(scenario[:heat_network_order]).to be_nil
      end
    end

    context 'with a custom interconnector 1 electricity price curve' do
      let(:preset_attachment) do
        preset
          .attachments
          .create(key: 'interconnector_1_price_curve')
      end

      let(:scenario_attachment) do
        scenario.attachments.first
      end

      before do
        preset_attachment.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
          filename: 'price_curve.csv',
          content_type: 'text/csv'
        )
      end

      it 'works' do
        expect(scenario_attachment.file).to be_attached
      end

      it 'creates a new attachment' do
        expect(scenario_attachment.file)
          .not_to eq(preset_attachment.file)
      end

      it 'has the same content as the original' do
        expect(scenario_attachment.file.download)
          .to eq(preset_attachment.file.download)
      end
    end

    context 'with a custom interconnector 2 electricity price curve' do
      let(:preset_attachment) do
        preset
          .attachments
          .create(key: 'interconnector_2_price_curve')
      end

      let(:scenario_attachment) do
        scenario.attachments.first
      end

      before do
        preset_attachment.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
          filename: 'price_curve.csv',
          content_type: 'text/csv'
        )
      end

      it 'works' do
        expect(scenario_attachment.file).to be_attached
      end

      it 'creates a new attachment' do
        expect(scenario_attachment.file)
          .not_to eq(preset_attachment.file)
      end

      it 'has the same content as the original' do
        expect(scenario_attachment.file.download)
          .to eq(preset_attachment.file.download)
      end
    end

    context 'with a preset heat network order' do
      let(:techs) do
        HeatNetworkOrder.default_order.shuffle
      end

      before do
        HeatNetworkOrder.create!(scenario: preset, order: techs)
      end

      it 'copies the flexibility order attributes' do
        expect(scenario.heat_network_order).to_not be_nil
        expect(scenario.heat_network_order.id).to_not eq(preset.heat_network_order.id)
        scenario.save!
        expect(scenario.heat_network_order.order).to eq(techs)
        expect(scenario.heat_network_order.scenario).to eq(scenario) # Not `preset`.
      end
    end
  end

  describe 'cloning a scaled scenario to an unscaled scenario' do
    let(:preset) do
      FactoryBot.create(:scenario, {
        id:              99999, # Avoid a collision with a preset ID
        user_values:     { 'grouped_input_one' => 2 },
        balanced_values: { 'grouped_input_two' => 8 },

        scaler: ScenarioScaling.new(
          area_attribute: 'present_number_of_residences',
          value:          1000
        )
      })
    end

    let(:scenario) do
      scenario = Scenario.new
      scenario.descale     = true
      scenario.scenario_id = preset.id
      scenario.save!

      scenario
    end

    let(:multiplier) { Atlas::Dataset.find(:nl).present_number_of_residences / 1000 }

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
        end_year:        2030,
        area_code:       'nl',
        user_values:     { 1 => 2, 3 => 4 },
        balanced_values: { 5 => 6 }
      )
    end

    before(:each) do
      scenario.inputs
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

    it 'does not clone the scenario ID' do
      expect(dup.id).to be_nil
    end

    it 're-generates the same present inputs as for the original' do
      expect(dup.inputs.present).to eq(scenario.inputs.present)
    end

    it 're-generates the same present future as for the original' do
      expect(dup.inputs.future).to eq(scenario.inputs.future)
    end

    it 'does not clone inputs' do
      expect(dup.inputs).not_to equal(scenario.inputs)
    end
  end

  context 'with two scenarios using the same attached curve' do
    let(:scenario_one_attachment) { FactoryBot.create(:scenario_attachment) }
    let(:scenario_two_attachment) { FactoryBot.create(:scenario_attachment) }

    before do
      scenario_one_attachment.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )

      scenario_two_attachment.file.attach(
        scenario_one_attachment.file.blob
      )

      scenario_one_attachment.scenario.reload
      scenario_two_attachment.scenario.reload
    end

    it 'the first scenario has a price curve' do
      expect(scenario_one_attachment.file).to be_attached
    end

    it 'the second scenario has a price curve' do
      expect(scenario_two_attachment.file).to be_attached
    end

    it 'the scenario have the same price curve blob' do
      expect(scenario_two_attachment.file.blob)
        .to eq(scenario_one_attachment.file.blob)
    end

    # Sanity check against Rails behaviour changing in the future.
    it 'the blob is not deleted when removed from one scenario' do
      expect { scenario_one_attachment.file.purge }
        .not_to change(ActiveStorage::Blob, :count)
    end

    it 'the reference is kept intact when removed from only one scenario' do
      scenario_one_attachment.file.purge
      expect(scenario_two_attachment.file).to be_attached
    end

    # Sanity check against Rails behaviour changing in the future.
    it 'the blob is deleted when removed from both scenarios' do
      scenario_one_attachment.file.purge

      expect { scenario_two_attachment.file.purge }
        .to change(ActiveStorage::Blob, :count).by(-1)
    end
  end

  describe '#metadata' do
    let(:scenario) { described_class.new }

    context 'with no metadata' do
      it 'responds with nil when requesting a key' do
        expect(scenario.metadata[:ctm_scenario_id]).to be_nil
      end
    end

    context 'with empty metadata' do
      before { scenario.metadata = {} }

      it 'responds with nil when requesting a key' do
        expect(scenario.metadata[:ctm_scenario_id]).to be_nil
      end
    end

    context 'with metadata present' do
      before { scenario.metadata = { ctm_scenario_id: 12_345, kittens: 'mew' } }

      it 'stores numeric data' do
        expect(scenario.metadata[:ctm_scenario_id]).to eq(12_345)
      end

      it 'stores string data' do
        expect(scenario.metadata[:kittens]).to eq('mew')
      end

      it 'does not have metadata accesible by accessor' do
        expect { scenario.kittens }.to raise_error(NoMethodError)
      end
    end

    context 'when setting metadata' do
      it 'permits JSON object' do
        scenario.metadata = JSON.generate({})
        expect(scenario.metadata).to eq({})
      end

      it 'permits a hash' do
        scenario.metadata = {}
        expect(scenario.metadata).to eq({})
      end

      it 'permits nil' do
        scenario.metadata = nil
        expect(scenario.metadata).to eq({})
      end

      it 'permits empty string' do
        scenario.metadata = ''
        expect(scenario.metadata).to eq({})
      end

      it 'denies objects larger than 64Kb' do
        scenario.metadata = (0..15_000).to_h { |i| [i, i] }

        expect(scenario).not_to be_valid
      end
    end

    context 'when creating a clone of a scenario' do
      before { scenario.metadata = { ctm_scenario_id: 12_345, kittens: 'mew' } }

      let(:scenario_clone) { described_class.new(scenario_id: scenario.id) }

      it 'keeps the original metadata' do
        expect(scenario.metadata).not_to eq({})
      end

      it 'does not copy the metadata' do
        expect(scenario_clone.metadata).to eq({})
      end
    end
  end
end
