# frozen_string_literal: true

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurvesCSVSerializer do
  let(:serializer) { described_class.new(curves, 2050, 'mine.csv') }

  context 'when given a valid config' do
    let(:curves) do
      [
        { name: 'Query one',   curve: [1, 2, 3] + ([0] * 8757) },
        { name: 'Query two',   curve: [4, 5, 6] + ([0] * 8757) },
        { name: 'Query three', curve: [7, 8, 9] + ([0] * 8757) }
      ]
    end

    it 'includes the CSV headers' do
      expect(serializer.to_csv_rows[0]).to eq(['Time', 'Query one', 'Query two', 'Query three'])
    end

    it 'includes the first row' do
      expect(serializer.to_csv_rows[1]).to eq(['2050-01-01 00:00', 1, 4, 7])
    end

    it 'includes the second row' do
      expect(serializer.to_csv_rows[2]).to eq(['2050-01-01 01:00', 2, 5, 8])
    end

    it 'includes the third row' do
      expect(serializer.to_csv_rows[3]).to eq(['2050-01-01 02:00', 3, 6, 9])
    end

    it 'creates a CSV' do
      expect(serializer.as_csv.lines.take(4)).to eq([
        "Time,Query one,Query two,Query three\n",
        "2050-01-01 00:00,1,4,7\n",
        "2050-01-01 01:00,2,5,8\n",
        "2050-01-01 02:00,3,6,9\n"
      ])
    end
  end

  context 'when given an empty curve' do
    let(:curves) do
      [
        { name: 'Query one', curve: [1, 2, 3] + ([0] * 8757) },
        { name: 'Query two', curve: [] }
      ]
    end

    it 'includes the CSV headers' do
      expect(serializer.to_csv_rows[0]).to eq(['Time', 'Query one', 'Query two'])
    end

    it 'includes the first row' do
      expect(serializer.to_csv_rows[1]).to eq(['2050-01-01 00:00', 1, 0])
    end

    it 'includes the second row' do
      expect(serializer.to_csv_rows[2]).to eq(['2050-01-01 01:00', 2, 0])
    end

    it 'includes the third row' do
      expect(serializer.to_csv_rows[3]).to eq(['2050-01-01 02:00', 3, 0])
    end

    it 'creates a CSV' do
      expect(serializer.as_csv.lines.take(4)).to eq([
        "Time,Query one,Query two\n",
        "2050-01-01 00:00,1,0\n",
        "2050-01-01 01:00,2,0\n",
        "2050-01-01 02:00,3,0\n"
      ])
    end
  end

  context 'when given a curve that is nil' do
    let(:curves) do
      [
        { name: 'Query one', curve: [1, 2, 3] + ([0] * 8757) },
        { name: 'Query two', curve: nil }
      ]
    end

    it 'includes the CSV headers' do
      expect(serializer.to_csv_rows[0]).to eq(['Time', 'Query one', 'Query two'])
    end

    it 'includes the first row' do
      expect(serializer.to_csv_rows[1]).to eq(['2050-01-01 00:00', 1, 0])
    end

    it 'includes the second row' do
      expect(serializer.to_csv_rows[2]).to eq(['2050-01-01 01:00', 2, 0])
    end

    it 'includes the third row' do
      expect(serializer.to_csv_rows[3]).to eq(['2050-01-01 02:00', 3, 0])
    end

    it 'creates a CSV' do
      expect(serializer.as_csv.lines.take(4)).to eq([
        "Time,Query one,Query two\n",
        "2050-01-01 00:00,1,0\n",
        "2050-01-01 01:00,2,0\n",
        "2050-01-01 02:00,3,0\n"
      ])
    end
  end
end
