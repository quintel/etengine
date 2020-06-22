require 'spec_helper'

describe Qernel::Slot::Loss do
  let(:graph) do
    layout = <<-LAYOUT.strip_heredoc
      electricity[1.0]:          network(100) == s(0.50) ==> supply_one
      electricity[0.4;0.4]:      output       == s(1.0)  ==> network
      coupling_carrier[1.0;1.0]: output       == s(1.0)  ==> network
      loss[1.0;0.1(loss)]:       irrelevant   == s(1.0)  ==> network
    LAYOUT

    Qernel::GraphParser.new(layout).build
  end

  let(:network) { graph.nodes.detect { |c| c.key == :network } }
  let(:loss)    { network.output(:loss) }

  before do
    # GraphParser adds a conversion; get rid of it.
    loss.dataset_attributes.delete(:conversion)
  end

  # --------------------------------------------------------------------------

  it 'ignores coupling carrier slots' do
    expect(loss.conversion).to eql(0.6)
  end

end # Qernel::Slot::Loss
