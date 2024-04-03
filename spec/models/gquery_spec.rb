require 'spec_helper'

describe Gquery do
  describe "#gql_modifier" do
    it "should return gql_modifier if existant in query" do
      gquery = Gquery.new(:query => "future:SUM(1,1)")
      expect(gquery.gql_modifier).to eq('future')
    end

    it "should return nil if not exists in query" do
      gquery = Gquery.new(:query => "SUM(1,1)")
      expect(gquery.gql_modifier).to eq(nil)
    end
  end

  describe '#labels' do
    let(:gquery) { described_class.all.select{|q| q.key == 'some_demand' }.first }

    it 'splits up all folders in the path as labels' do
      expect(gquery.labels.size).not_to be_zero
    end

    it 'has the correct label' do
      expect(gquery.labels.first).to eq('final_demand')
    end

    it 'does not include the home directory' do
      expect(gquery.labels).not_to include('etsource')
    end

    it 'does not include the queries name' do
      expect(gquery.labels).not_to include("#{gquery.key}.gql")
    end
  end

  describe '.filter_by' do
    let(:label) { 'final_demand' }
    let(:gqueries) { described_class.filter_by(label) }

    it 'returns only one query' do
      expect(gqueries.length).to eq(1)
    end

    it 'returns only a query with the correct label' do
      expect(gqueries.first.labels).to include(label)
    end
  end
end
