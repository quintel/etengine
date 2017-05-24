require 'spec_helper'

describe Qernel::Plugins::Merit::CurvePeakFinder do
  let(:month) { 8760 / 12 }
  let(:peaks) { described_class.peaks(curve) }

  context 'with winter evening peak at 04:00 Jan 1st' do
    let(:curve) do
      # Morning Jan 1st...
      [1.0, 1.0, 1.0, 1.0, 1.5, 1.0] +
        # Rest of year...
        ([0.0] * (month * 12 - 12)) +
        # Night Dec 31st
        [1.4, 1.0, 1.0, 1.0, 1.0, 1.0]
    end

    it('identifies the winter evening peak') { expect(peaks[:we]).to eq(1.5) }
    it('has no winter daytime peak') { expect(peaks[:wd]).to eq(0) }
    it('has no summer daytime peak') { expect(peaks[:sd]).to eq(0) }
    it('has no summer evening peak') { expect(peaks[:se]).to eq(0) }
  end

  context 'with winter evening peak at 00:00 Oct 1st' do
    let(:curve) do
      # Beginning of the year
      ([0.0] * (month * 9)) +
        # Oct 1st
        [2.0] +
        # Rest of year...
        ([0.0] * (month * 3 - 1))
    end

    it('identifies the winter evening peak') { expect(peaks[:we]).to eq(2.0) }
    it('has no winter daytime peak') { expect(peaks[:wd]).to eq(0) }
    it('has no summer daytime peak') { expect(peaks[:sd]).to eq(0) }
    it('has no summer evening peak') { expect(peaks[:se]).to eq(0) }
  end

  context 'with winter daytime peak at 08:00 Jan 1st' do
    let(:curve) do
      # Morning Jan 1st...
      ([0.0] * 8) + [1.8] +
        # Rest of year...
        ([0.0] * (month * 12 - 9))
    end

    it('identifies the winter daytime peak') { expect(peaks[:wd]).to eq(1.8) }
    it('has no winter evening peak') { expect(peaks[:we]).to eq(0) }
    it('has no summer daytime peak') { expect(peaks[:sd]).to eq(0) }
    it('has no summer evening peak') { expect(peaks[:se]).to eq(0) }
  end

  context 'with winter evening peak at 12:00 Oct 1st' do
    let(:curve) do
      # Beginning of the year
      ([0.0] * (month * 9 + 12)) +
        # Oct 1st
        [2.0] +
        # Rest of year...
        ([0.0] * (month * 3 - 13))
    end

    it('identifies the winter daytime peak') { expect(peaks[:wd]).to eq(2.0) }
    it('has no winter evening peak') { expect(peaks[:we]).to eq(0) }
    it('has no summer daytime peak') { expect(peaks[:sd]).to eq(0) }
    it('has no summer evening peak') { expect(peaks[:se]).to eq(0) }
  end

  context 'with summer daytime peak at 08:00 Apr 1st' do
    let(:curve) do
      # Beginning of the year
      ([0.0] * (month * 3 + 8)) +
        # Apr 1st
        [2.3] +
        # Rest of year...
        ([0.0] * (month * 9 - 9))
    end

    it('has no winter daytime peak') { expect(peaks[:wd]).to eq(0) }
    it('has no winter evening peak') { expect(peaks[:we]).to eq(0) }
    it('identifies the summer daytime peak') { expect(peaks[:sd]).to eq(2.3) }
    it('has no summer evening peak') { expect(peaks[:se]).to eq(0) }
  end

  context 'with summer night peak at 18:00 Apr 1st' do
    let(:curve) do
      # Beginning of the year
      ([0.0] * (month * 3 + 18)) +
        # Apr 1st
        [2.2] +
        # Rest of year...
        ([0.0] * (month * 9 - 19))
    end

    it('has no winter daytime peak') { expect(peaks[:wd]).to eq(0) }
    it('has no winter evening peak') { expect(peaks[:we]).to eq(0) }
    it('has no summer daytime peak') { expect(peaks[:sd]).to eq(0) }
    it('identifies the summer evening peak') { expect(peaks[:se]).to eq(2.2) }
  end

  context 'given an empty curve' do
    let(:curve) { [] }

    it 'raises an error' do
      expect { peaks }.to raise_error(/must contain 8760 frames; got 0/)
    end
  end

  context 'given a curve with 8759 points' do
    let(:curve) { [1.0] * 8759 }

    it 'raises an error' do
      expect { peaks }.to raise_error(/must contain 8760 frames; got 8759/)
    end
  end

  context 'given a curve with 17520 points' do
    let(:curve) { [1.0] * (8760 * 2) }

    it 'raises an error' do
      expect { peaks }.to raise_error(/must contain 8760 frames; got 17520/)
    end
  end
end
