require 'spec_helper'

describe Dataset::SlotData do
  it { should belong_to :dataset }
  it { should belong_to :slot }
end

