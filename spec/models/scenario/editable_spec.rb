# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Scenario::Editable do
  # Updates
  # -------

  describe '#update!' do
    let(:scenario) { FactoryBot.create(:scenario) }
    let(:editable) { described_class.new(scenario) }

    context 'with values' do
      let(:update) do
        editable.update!(
          user_values: "---\nfoo: bar",
          balanced_values: "---\nbaz: qux",
          metadata: '{"a": "b"}',
          api_read_only: true
        )
      end

      it 'returns true' do
        expect(update).to be(true)
      end

      it 'has no errors' do
        update
        expect(editable.errors).to be_empty
      end

      it 'raises no errors' do
        expect { update }.not_to raise_error
      end

      it 'saves the user values' do
        expect { update }.to change { scenario.reload.user_values }
          .from({})
          .to("foo" => "bar")
      end

      it 'saves the balanced values' do
        expect { update }.to change { scenario.reload.balanced_values }
          .from({})
          .to("baz" => "qux")
      end

      it 'saves the metadata' do
        expect { update }.to change { scenario.reload.metadata }
          .from({})
          .to("a" => "b")
      end

      it 'saves the changed attributes' do
        expect { update }.to change { scenario.reload.api_read_only? }
          .from(false)
          .to(true)
      end
    end

    context 'with a parse error' do
      let(:update) do
        editable.update!(
          user_values: "---\na: b: c",
          balanced_values: "---\nbaz: qux",
          metadata: '{"a": "b"}',
          api_read_only: true
        )
      end

      let(:update_ignoring_errors) do
        begin
          update
        rescue ActiveRecord::RecordInvalid
        end
      end

      it 'raises an error' do
        expect { update }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'has errors' do
        update_ignoring_errors
        expect(editable.errors).not_to be_empty
      end

      it 'does not change the user values' do
        expect { update_ignoring_errors }.not_to change { scenario.reload.user_values }
      end

      it 'does not change the balanced values' do
        expect { update_ignoring_errors }.not_to change { scenario.reload.balanced_values }
      end

      it 'does not change the metadata' do
        expect { update_ignoring_errors }.not_to change { scenario.reload.metadata }
      end

      it 'does not change the attributes' do
        expect { update_ignoring_errors }.not_to change { scenario.reload.api_read_only? }
      end
    end
  end

  # User values
  # -----------

  describe '#user_values' do
    it 'converts user values to YAML' do
      scenario = Scenario.new(user_values: { 'foo' => 'bar' })
      editable = described_class.new(scenario)

      expect(editable.user_values).to eq(<<~YAML.rstrip)
        foo: bar
      YAML
    end

    it 'converts when the scenario has blank user values' do
      scenario = Scenario.new(user_values: {})
      editable = described_class.new(scenario)

      expect(editable.user_values).to eq('')
    end

    it 'converts when the scenario has user values of nil' do
      scenario = Scenario.new(user_values: nil)
      editable = described_class.new(scenario)

      expect(editable.user_values).to eq('')
    end
  end

  describe '#user_values' do
    let(:scenario) { Scenario.new(user_values: { 'foo' => 'bar' }) }
    let(:editable) { described_class.new(scenario) }

    context 'with no content' do
      before do
        editable.user_values = ''
      end

      it 'sets empty user values on the scenario' do
        expect(scenario.user_values).to eq({})
      end

      it 'sets the raw user values' do
        expect(editable.user_values).to eq('')
      end

      it 'has no errors' do
        expect(editable.errors[:user_values]).to be_empty
      end
    end

    context 'with valid YAML' do
      before do
        editable.user_values = <<~YAML
          foo: bar
          baz: qux
        YAML
      end

      it 'sets the user values on the scenario' do
        expect(scenario.user_values).to eq('foo' => 'bar', 'baz' => 'qux')
      end

      it 'sets the raw values on the editable' do
        expect(editable.user_values).to eq(<<~YAML.rstrip)
          foo: bar
          baz: qux
        YAML
      end

      it 'has no errors' do
        expect(editable.errors[:user_values]).to be_empty
      end
    end

    context 'with invalid YAML' do
      before do
        editable.user_values = <<~YAML
          a: b: c
        YAML
      end

      it 'makes no changes to the scenario' do
        expect(scenario.user_values).to eq('foo' => 'bar')
      end

      it 'sets the raw values on the editable' do
        expect(editable.user_values).to eq(<<~YAML.rstrip)
          a: b: c
        YAML
      end

      it 'has an error on user_values' do
        expect(editable.errors[:user_values]).to include(
          'is not valid YAML: (<unknown>): mapping values are not allowed in this context at ' \
          'line 1 column 5'
        )
      end
    end
  end

  # Balanced values
  # ---------------

  describe '#balanced_values' do
    it 'converts balanced values to YAML' do
      scenario = Scenario.new(balanced_values: { 'foo' => 'bar' })
      editable = described_class.new(scenario)

      expect(editable.balanced_values).to eq(<<~YAML.rstrip)
        foo: bar
      YAML
    end

    it 'converts when the scenario has blank balanced values' do
      scenario = Scenario.new(balanced_values: {})
      editable = described_class.new(scenario)

      expect(editable.balanced_values).to eq('')
    end

    it 'converts when the scenario has balanced values of nil' do
      scenario = Scenario.new(balanced_values: nil)
      editable = described_class.new(scenario)

      expect(editable.balanced_values).to eq('')
    end
  end

  describe '#balanced_values' do
    let(:scenario) { Scenario.new(balanced_values: { 'foo' => 'bar' }) }
    let(:editable) { described_class.new(scenario) }

    context 'with no content' do
      before do
        editable.balanced_values = ''
      end

      it 'sets empty balanced values on the scenario' do
        expect(scenario.balanced_values).to eq({})
      end

      it 'sets the raw balanced values' do
        expect(editable.balanced_values).to eq('')
      end

      it 'has no errors' do
        expect(editable.errors[:balanced_values]).to be_empty
      end
    end

    context 'with valid YAML' do
      before do
        editable.balanced_values = <<~YAML
          foo: bar
          baz: qux
        YAML
      end

      it 'sets the balanced values on the scenario' do
        expect(scenario.balanced_values).to eq('foo' => 'bar', 'baz' => 'qux')
      end

      it 'sets the raw values on the editable' do
        expect(editable.balanced_values).to eq(<<~YAML.rstrip)
          foo: bar
          baz: qux
        YAML
      end

      it 'has no errors' do
        expect(editable.errors[:balanced_values]).to be_empty
      end
    end

    context 'with invalid YAML' do
      before do
        editable.balanced_values = <<~YAML
          a: b: c
        YAML
      end

      it 'makes no changes to the scenario' do
        expect(scenario.balanced_values).to eq('foo' => 'bar')
      end

      it 'sets the raw values on the editable' do
        expect(editable.balanced_values).to eq(<<~YAML.rstrip)
          a: b: c
        YAML
      end

      it 'has an error on balanced_values' do
        expect(editable.errors[:balanced_values]).to include(
          'is not valid YAML: (<unknown>): mapping values are not allowed in this context at ' \
          'line 1 column 5'
        )
      end
    end
  end

  # Metadata
  # --------

  describe '#metadata' do
    it 'converts metadata to YAML' do
      scenario = Scenario.new(metadata: { 'foo' => 'bar' })
      editable = described_class.new(scenario)

      expect(editable.metadata).to eq(<<~JSON.rstrip)
        {
          "foo": "bar"
        }
      JSON
    end

    it 'converts when the scenario has blank metadata' do
      scenario = Scenario.new(metadata: {})
      editable = described_class.new(scenario)

      expect(editable.metadata).to eq('{}')
    end

    it 'converts when the scenario has balanced values of nil' do
      scenario = Scenario.new(metadata: nil)
      editable = described_class.new(scenario)

      expect(editable.metadata).to eq('{}')
    end
  end


  describe '#metadata' do
    let(:scenario) { Scenario.new(metadata: { 'foo' => 'bar' }) }
    let(:editable) { described_class.new(scenario) }

    context 'with no content' do
      before do
        editable.metadata = ''
      end

      it 'sets empty metadata on the scenario' do
        expect(scenario.metadata).to eq({})
      end

      it 'sets the raw metadata' do
        expect(editable.metadata).to eq('{}')
      end

      it 'has no errors' do
        expect(editable.errors[:metadata]).to be_empty
      end
    end

    context 'with valid JSON' do
      before do
        editable.metadata = <<~JSON
          {
            "foo": "bar",
            "baz": "qux"
          }
        JSON
      end

      it 'sets the metadata on the scenario' do
        expect(scenario.metadata).to eq('foo' => 'bar', 'baz' => 'qux')
      end

      it 'sets the raw values on the editable' do
        expect(editable.metadata).to eq(<<~JSON.rstrip)
          {
            "foo": "bar",
            "baz": "qux"
          }
        JSON
      end

      it 'has no errors' do
        expect(editable.errors[:metadata]).to be_empty
      end
    end

    context 'with invalid JSON' do
      before do
        editable.metadata = '{'
      end

      it 'makes no changes to the scenario' do
        expect(scenario.metadata).to eq('foo' => 'bar')
      end

      it 'sets the raw values on the editable' do
        expect(editable.metadata).to eq('{')
      end

      it 'has an error on metadata' do
        expect(editable.errors[:metadata]).to include(
          "is not valid JSON: 859: unexpected token at '{'"
        )
      end
    end
  end
end
