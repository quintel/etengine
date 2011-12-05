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
#  max_demand :integer(8)
#

class Dataset::LinkData < ActiveRecord::Base
  include Dataset::TouchOnUpdate

  belongs_to :dataset
  belongs_to :link
  
  validates :dataset, :presence => true
  validates :link,    :presence => true

  def dataset_key
    Qernel::Link.compute_dataset_key(link_id)
  end

  def dataset_attributes
    # TODO fix that link_type hack
    val = if ((link_type == 4 and share.present?) == true) # 4 = constant
      self.share
    else
      nil
    end
    {
      :share => share.andand.to_f,
      :value => val,
      :max_demand => max_demand
    }
  end
end
