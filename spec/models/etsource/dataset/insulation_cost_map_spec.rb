require 'spec_helper'

describe Etsource::Dataset::InsulationCostMap do
  let(:map) do
    described_class.new(Atlas::Dataset::InsulationCostCSV.read(csv.path.to_s))
  end

  after do
    csv.close
    csv.unlink
  end

  context 'with a 3x3 map' do
    let(:csv) do
      file = Tempfile.new('insulation_upgrade_cost.csv')

      file.puts(<<-CSV.lines.map(&:strip).join("\n"))
        present,    0,        1,       2,      3
        0,          0,       10,      20,     30
        1,       -100,        0,     100,    200
        2,       -2000,   -1000,       0,   1000
        3,      -30000,  -20000,  -10000,      0
        4,     -300000, -200000, -100000,      0
      CSV

      file.rewind
      file
    end

    it 'retrieves costs from 0,0' do
      expect(map.get(0, 0)).to eq(0)
    end

    it 'retrieves costs from 1,0' do
      expect(map.get(1, 0)).to eq(-100)
    end

    it 'retrieves costs from 3,0' do
      expect(map.get(3, 0)).to eq(-30_000)
    end

    it 'retrieves costs from 2,3' do
      expect(map.get(2, 3)).to eq(1000)
    end

    it 'retrieves costs from 3,3' do
      expect(map.get(3, 3)).to eq(0)
    end

    it 'retrieves costs from 4,2' do
      expect(map.get(4, 2)).to eq(-100000)
    end

    it 'returns a fallback cost for -1,0' do
      expect(map.get(-1, 0)).to eq(0)
    end

    it 'returns a fallback cost for -1,-1' do
      expect(map.get(-1, 1)).to eq(10)
    end

    it 'returns a fallback cost for 1,-1' do
      expect(map.get(1, -1)).to eq(-100)
    end

    it 'returns a fallback cost for 2,8' do
      expect(map.get(2, 8)).to eq(1000)
    end

    it 'returns a fallback cost for 5,3' do
      expect(map.get(5, 3)).to eq(-0)
    end

    it 'returns a fallback cost for 5,0' do
      expect(map.get(4, 0)).to eq(-300_000)
    end
  end

  context 'with a keyed (new build) map' do
    let(:csv) do
      file = Tempfile.new('insulation_upgrade_cost.csv')

      file.puts(<<-CSV.lines.map(&:strip).join("\n"))
        type,         0,  1,    2,      3
        apartments,  10,  20,  30,     40
        buildings,  100, 200, 300,    400
      CSV

      file.rewind
      file
    end

    it 'retrieves costs for apartments,0' do
      expect(map.get(:apartments, 0)).to eq(10)
    end

    it 'retrieves costs for apartments,3' do
      expect(map.get(:apartments, 3)).to eq(40)
    end

    it 'retrieves a fallback value for apartments,4' do
      expect(map.get(:apartments, 4)).to eq(40)
    end

    it 'retrieves a fallback value for apartments,-1' do
      expect(map.get(:apartments, -1)).to eq(10)
    end

    it 'retrieves costs for buildings,0' do
      expect(map.get(:buildings, 0)).to eq(100)
    end

    it 'retrieves costs for buildings,3' do
      expect(map.get(:buildings, 3)).to eq(400)
    end

    it 'raises an error when accessing nope,0' do
      expect { map.get(:nope, 0) }.to raise_error(Atlas::UnknownCSVRowError)
    end
  end
end
