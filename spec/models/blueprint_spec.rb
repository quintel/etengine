require 'spec_helper'

describe Blueprint do
  it { should belong_to :blueprint_model }
  it { should have_many :datasets }
  it { should have_many :links }
  it { should have_many :slots }
end
