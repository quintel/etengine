# == Schema Information
#
# Table name: link_datas
#
#  id         :integer(4)      not null, primary key
#  link_type  :integer(4)      default(0)
#  share      :float
#  created_at :datetime
#  updated_at :datetime
#  dataset_id :integer(4)
#  link_id    :integer(4)
#

class Dataset::LinkData < ActiveRecord::Base
  include Dataset::TouchOnUpdate

  belongs_to :dataset
  belongs_to :link

  def dataset_key
    Qernel::DatasetItem.compute_dataset_key(Qernel::Link, link_id)
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
      :value => val
    }
  end
end
