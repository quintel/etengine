require 'spec_helper'

describe Dataset::LinkData do
  it { should belong_to :dataset }
  it { should belong_to :link }
end

# == Schema Information
#
# Table name: dataset_link_data
#
#  id         :integer(4)      not null, primary key
#  link_type  :integer(4)      default(0)
#  share      :float
#  created_at :datetime
#  updated_at :datetime
#  dataset_id :integer(4)
#  link_id    :integer(4)
#

