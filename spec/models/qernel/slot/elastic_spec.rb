require 'spec_helper'

describe Qernel::Slot::Elastic do
  let(:graph) do
    layout = <<-LAYOUT.strip_heredoc
      electricity[1.0]:       network(100) == s(0.50) ==> supply_one
      electricity[0.4;0.4]:   output       == s(1.0)  ==> network
      useable_heat[0.5;0.5]:  output       == s(1.0)  ==> network
      loss[1.0;0.1(elastic)]: irrelevant   == s(1.0)  ==> network
    LAYOUT

    Qernel::GraphParser.new(layout).build
  end

  let(:network)     { graph.nodes.detect { |c| c.key == :network } }
  let(:loss)        { network.output(:loss) }
  let(:heat)        { network.output(:useable_heat) }
  let(:electricity) { network.output(:electricity) }

  before do
    # GraphParser adds a conversion; get rid of it.
    loss.dataset_attributes.delete(:conversion)
  end

  # --------------------------------------------------------------------------

  it 'calculates loss dynamically' do
    # Stupid floating points. :<
    expect(loss.conversion).to be_within(0.000001).of(0.1)
  end

  it 'changes when the efficiency of other outputs change' do
    heat.dataset_set(:conversion, 0.2)
    electricity.dataset_set(:conversion, 0.3)

    expect(loss.conversion).to eql(0.5)
  end

  it 'is 1.0 when the node has no other outputs' do
    allow(loss).to receive(:siblings).and_return([])
    expect(loss.conversion).to eql(1.0)
  end

  it 'is 0.0 if the node breaks the first law of thermodynamics' do
    heat.dataset_set(:conversion, 0.6)
    electricity.dataset_set(:conversion, 0.6)

    expect(loss.conversion).to eql(0.0)
  end

  it 'uses the dataset value when present' do
    loss.dataset_set(:conversion, 0.75)
    expect(loss.conversion).to eql(0.75)
  end

  it 'raises an error if a node has two elastic slots' do
    layout = <<-LAYOUT.strip_heredoc
      loss[0.5;0.5(elastic)]:        irrelevant   == s(1.0)  ==> network
      electricity[0.5;0.5(elastic)]: irrelevant   == s(1.0)  ==> network
    LAYOUT

    expect(-> { Qernel::GraphParser.new(layout).build }).to \
      raise_error(Qernel::Slot::Elastic::TooManyElasticSlots,
                 /already has an elastic slot/)
  end

end # Qernel::Slot::Elastic
