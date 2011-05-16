require 'spec_helper'

describe Dataset::ConverterData do
  it { should belong_to :dataset }
  it { should belong_to :converter }
end
