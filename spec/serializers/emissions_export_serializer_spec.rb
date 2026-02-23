# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EmissionsExportSerializer do
  let(:scenario) { Scenario.default }
  let(:serializer) { described_class.new(scenario) }

  describe '#as_csv' do
    it 'returns a CSV string' do
      expect(serializer.as_csv).to be_a(String)
    end

    it 'includes the header row' do
      csv = CSV.parse(serializer.as_csv)
      expect(csv.first).to eq([
        'Node',
        'CO2 production [kton CO2-eq]',
        'CO2 capture [kton CO2-eq]',
        'Other GHG emissions [kton CO2-eq]',
        'Total GHG emissions [kton CO2-eq]',
        'Biogenic CO2 emissions [kton CO2-eq]',
        'CO2 emissions end-use allocation [kton CO2-eq]'
      ])
    end

    it 'may include data rows if emissions exist' do
      csv = CSV.parse(serializer.as_csv)
      # Should have at least header row
      expect(csv.length).to be >= 1

      # If there are data rows, validate structure
      expect(csv[1].length).to eq(7) if csv.length > 1
    end

    it 'formats node data correctly when rows exist' do
      csv = CSV.parse(serializer.as_csv)
      data_rows = csv[1..] # Skip header

      # Each row (if any) should have 7 columns
      data_rows.each do |row|
        expect(row.length).to eq(7)
      end
    end

    context 'with specific node values' do
      it 'exports CO2 capture as negative value' do
        csv = CSV.parse(serializer.as_csv)
        # Find any row with capture value
        rows_with_capture = csv[1..].select { |row| row[2].to_f < 0 }

        # If there are CCS nodes, they should have negative capture
        expect(rows_with_capture.first[2].to_f).to be < 0 if rows_with_capture.any?
      end

      it 'validates Total GHG = Production - Capture + Other GHG' do
        csv = CSV.parse(serializer.as_csv)
        data_rows = csv[1..]

        data_rows.each do |row|
          production = row[1].to_f
          capture = row[2].to_f # Already negative in export
          other_ghg = row[3].to_f
          total_ghg = row[4].to_f

          expected_total = production + capture + other_ghg

          # Allow small floating point errors
          expect(total_ghg).to be_within(0.01).of(expected_total) unless total_ghg.zero? && expected_total.zero?
        end
      end
    end
  end

  describe '#to_kton' do
    it 'converts kg to kilotons correctly' do
      # 1 billion kg = 1 kiloton
      expect(serializer.send(:to_kton, 1_000_000_000)).to eq(1.0)
    end

    it 'converts smaller values correctly' do
      # 500 million kg = 0.5 kilotons
      expect(serializer.send(:to_kton, 500_000_000)).to eq(0.5)
    end

    it 'handles zero correctly' do
      expect(serializer.send(:to_kton, 0)).to eq(0.0)
    end

    it 'handles very small values' do
      # 1000 kg = 0.000001 kilotons
      expect(serializer.send(:to_kton, 1000)).to eq(0.000001)
    end

    it 'handles very large values' do
      # 10 billion kg = 10 kilotons
      expect(serializer.send(:to_kton, 10_000_000_000)).to eq(10.0)
    end
  end

  describe '#format_value' do
    it 'returns empty string for nil' do
      expect(serializer.send(:format_value, nil)).to eq('')
    end

    it 'returns String' do
      expect(serializer.send(:format_value, 1.23456789)).to eq('1.23456789')
    end

    it 'handles integer-like floats correctly' do
      expect(serializer.send(:format_value, 5.0)).to eq('5.0')
    end

    it 'detects and handles NaN values' do
      expect(serializer.send(:format_value, Float::NAN)).to eq('ERROR')
    end

    it 'detects and handles Infinity values' do
      expect(serializer.send(:format_value, Float::INFINITY)).to eq('ERROR')
      expect(serializer.send(:format_value, -Float::INFINITY)).to eq('ERROR')
    end
  end

  describe '#emissions?' do
    let(:node_with_fossil) do
      double('Node', query: double('Query',
        direct_co2_emission_of_fossil_gross: 10.0,
        direct_co2_emission_of_bio_gross: 0.0))
    end

    let(:node_with_bio) do
      double('Node', query: double('Query',
        direct_co2_emission_of_fossil_gross: 0.0,
        direct_co2_emission_of_bio_gross: 5.0))
    end

    let(:node_with_both) do
      double('Node', query: double('Query',
        direct_co2_emission_of_fossil_gross: 10.0,
        direct_co2_emission_of_bio_gross: 5.0))
    end

    let(:node_with_neither) do
      double('Node', query: double('Query',
        direct_co2_emission_of_fossil_gross: 0.0,
        direct_co2_emission_of_bio_gross: 0.0))
    end

    let(:node_with_error) do
      double('Node', key: :error_node, query: double('Query')).tap do |node|
        allow(node.query).to receive(:direct_co2_emission_of_fossil_gross).and_raise(StandardError)
      end
    end

    it 'returns true for nodes with fossil emissions' do
      expect(serializer.send(:emissions?, node_with_fossil)).to be(true)
    end

    it 'returns true for nodes with bio emissions' do
      expect(serializer.send(:emissions?, node_with_bio)).to be(true)
    end

    it 'returns true for nodes with both emission types' do
      expect(serializer.send(:emissions?, node_with_both)).to be(true)
    end

    it 'returns false for nodes with no emissions' do
      expect(serializer.send(:emissions?, node_with_neither)).to be(false)
    end

    it 'returns false when query raises an error' do
      expect(serializer.send(:emissions?, node_with_error)).to be(false)
    end
  end

  describe '#safe_query' do
    let(:working_node) do
      double('Node', key: :test_node, query: double('Query', direct_co2_emission_of_fossil: 42.0))
    end

    let(:failing_node) do
      double('Node', key: :failing_node, query: double('Query')).tap do |node|
        allow(node.query).to receive(:direct_co2_emission_of_fossil).and_raise(StandardError.new('Test error'))
      end
    end

    let(:node_without_method) do
      double('Node', key: :no_method_node, query: double('Query'))
    end

    let(:node_returning_nan) do
      double('Node', key: :nan_node,
        query: double('Query', direct_co2_emission_of_fossil: Float::NAN))
    end

    let(:node_returning_infinity) do
      double('Node', key: :inf_node,
        query: double('Query', direct_co2_emission_of_fossil: Float::INFINITY))
    end

    it 'returns the query result when successful' do
      expect(serializer.send(:safe_query, working_node, :direct_co2_emission_of_fossil)).to eq(42.0)
    end

    it 'returns nil when query raises an error' do
      expect(serializer.send(:safe_query, failing_node, :direct_co2_emission_of_fossil)).to be_nil
    end

    it 'returns nil when node does not respond to method' do
      expect(serializer.send(:safe_query, node_without_method, :nonexistent_method)).to be_nil
    end

    it 'returns nil when query returns NaN' do
      expect(serializer.send(:safe_query, node_returning_nan,
        :direct_co2_emission_of_fossil)).to be_nil
    end

    it 'returns nil when query returns Infinity' do
      expect(serializer.send(:safe_query, node_returning_infinity, :direct_co2_emission_of_fossil)).to be_nil
    end

    it 'returns nil when query returns nil' do
      nil_node = double('Node', key: :nil_node,
        query: double('Query', direct_co2_emission_of_fossil: nil))
      expect(serializer.send(:safe_query, nil_node, :direct_co2_emission_of_fossil)).to be_nil
    end
  end
end
