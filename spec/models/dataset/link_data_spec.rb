require 'spec_helper'

describe Dataset::LinkData do
  it { should belong_to :dataset }
  it { should belong_to :link }
end

