require 'spec_helper'

describe Gql::Gql do
  let(:scenario) { FactoryGirl.create(:scenario, area_code: 'ameland') }
  let(:gql) { Gql::Gql.new(scenario) }

  describe "with correct initial inputs" do
    before { gql.prepare }

    # Setting the demand of foo to 50.0
    it 'updates the present graph with initializer inputs' do
      expect(gql.present.graph.converter(:foo).demand).to eq(50.0)
    end

    it 'updates the future graph with initializer inputs' do
      expect(gql.future.graph.converter(:foo).demand).to eq(50.0)
    end

    # Setting the demand of baz to 50.0
    it 'updates the present graph with initializer inputs' do
      expect(gql.present.graph.converter(:baz).demand).to eq(50.0)
    end

    it 'updates the future graph with initializer inputs' do
      expect(gql.future.graph.converter(:baz).demand).to eq(50.0)
    end

    # Setting the edge share between foo-baz to 0.5
    describe "share value" do
      it 'updates the present graph with initializer inputs' do
        expect(gql.present.graph.link(:"baz-foo@electricity").share).to eq(0.5)
      end

      it 'updates the future graph with initializer inputs' do
        expect(gql.future.graph.link(:"baz-foo@electricity").share).to eq(0.5)
      end
    end

    # Setting the reserved fraction of baz to 1.0
    describe "reserved fraction" do
      it 'updates the present graph with initializer inputs' do
        expect(gql.present.graph.converter(:baz)
          .converter_api.reserved_fraction).to eq(1.0)
      end

      it 'updates the future graph with initializer inputs' do
        expect(gql.future.graph.converter(:baz)
          .converter_api.reserved_fraction).to eq(1.0)
      end
    end

    # Setting the slot conversion of gas of converter_fixture_for_slots
    describe "reserved fraction" do
      it 'updates the present graph with initializer inputs' do
        slot = gql.present.graph.converter(:converter_fixture_for_slots)
          .slots.detect{ |slot| slot.carrier.key == :gas }

        expect(slot.conversion).to eq(0.5)
      end

      it 'updates the future graph with initializer inputs' do
        slot = gql.future.graph.converter(:converter_fixture_for_slots)
          .slots.detect{ |slot| slot.carrier.key == :gas }

        expect(slot.conversion).to eq(0.5)
      end
    end
  end

  describe 'use_network_calculations' do
    it 'is unchanged for unscaled scenarios' do
      gql.prepare
      expect(gql.future.graph.area.use_network_calculations).to eql(true)
    end

    it 'is false for scaled scenarios' do
      scenario.build_scaler(base_value: 1000, value: 10)
      gql.prepare
      expect(gql.future.graph.area.use_network_calculations).to eql(false)
    end
  end
end
