require 'spec_helper'

describe 'Etsource::SlotToken' do
  let(:parsed) { Etsource::SlotToken.find(line) }
  let(:slot)   { parsed.first }

  context 'with "(loss)-fusion"' do
    let(:line) { '(loss)-fusion' }

    it 'should create one SlotToken' do
      expect(parsed.size).to eq(1)
    end

    it 'should set the carrier to be :loss' do
      expect(slot.carrier_key).to eql(:loss)
    end

    it 'should set the key to be "(loss)-fusion"' do
      expect(slot.key).to eql('(loss)-fusion')
    end

    it 'should set the node key to be :fusion' do
      expect(slot.node_key).to eql(:fusion)
    end

    it 'should set the direction to be :output' do
      expect(slot.direction).to eql(:output)
    end

    it 'should have no :type data' do
      expect(slot.data(:type)).to be_nil
    end
  end

  context 'with "fusion-(loss)"' do
    let(:line) { 'fusion-(loss)' }

    it 'should create one SlotToken' do
      expect(parsed.size).to eq(1)
    end

    it 'should set the carrier to be :loss' do
      expect(slot.carrier_key).to eql(:loss)
    end

    it 'should set the key to be "(loss)-fusion"' do
      expect(slot.key).to eql('fusion-(loss)')
    end

    it 'should set the node key to be :fusion' do
      expect(slot.node_key).to eql(:fusion)
    end

    it 'should set the direction to be :input' do
      expect(slot.direction).to eql(:input)
    end

    it 'should have no :type data' do
      expect(slot.data(:type)).to be_nil
    end
  end

  context 'with "(loss)-fusion: {}"' do
    let(:line) { '(loss)-fusion: {}' }

    it 'should create one SlotToken' do
      expect(parsed.size).to eq(1)
    end

    it 'should set the carrier to be :loss' do
      expect(slot.carrier_key).to eql(:loss)
    end

    it 'should set the key to be "(loss)-fusion"' do
      expect(slot.key).to eql('(loss)-fusion')
    end

    it 'should set the node key to be :fusion' do
      expect(slot.node_key).to eql(:fusion)
    end

    it 'should set the direction to be :output' do
      expect(slot.direction).to eql(:output)
    end

    it 'should have no :type data' do
      expect(slot.data(:type)).to be_nil
    end
  end

  context 'with "(loss)-fusion: {type: :elastic}"' do
    let(:line) { '(loss)-fusion: {type: :elastic}' }

    it 'should create one SlotToken' do
      expect(parsed.size).to eq(1)
    end

    it 'should set the carrier to be :loss' do
      expect(slot.carrier_key).to eql(:loss)
    end

    it 'should set the key to be "(loss)-fusion"' do
      expect(slot.key).to eql('(loss)-fusion')
    end

    it 'should set the node key to be :fusion' do
      expect(slot.node_key).to eql(:fusion)
    end

    it 'should set the direction to be :output' do
      expect(slot.direction).to eql(:output)
    end

    it 'should set :type data to be :elastic' do
      expect(slot.data(:type)).to eql(:elastic)
    end
  end

  context 'with "(loss)-fusion (electricity)-fusion: {type: :elastic}"' do
    let(:line) { '(loss)-fusion (electricity)-fusion: {type: :elastic}' }

    it 'should create two SlotTokens' do
      expect(parsed.size).to eq(2)
    end

    it 'should set the carriers to be :loss and :electricity' do
      expect(parsed[0].carrier_key).to eql(:loss)
      expect(parsed[1].carrier_key).to eql(:electricity)
    end

    it 'should set the node keys to be :fusion' do
      expect(parsed[0].node_key).to eql(:fusion)
      expect(parsed[1].node_key).to eql(:fusion)
    end

    it 'should set :type data for the electricity slot' do
      expect(parsed[0].data(:type)).to be_nil
      expect(parsed[1].data(:type)).to eql(:elastic)
    end
  end

end # Etsource::Topology
