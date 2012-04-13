# == Schema Information
#
# Table name: input_tool_forms
#
#  id         :integer(4)      not null, primary key
#  area_code  :string(255)
#  code       :string(255)
#  values     :text
#  created_at :datetime
#  updated_at :datetime
#

module InputTool
  # SavedWizard keep the input data of researchers temporarly in the database.
  # They are assigned country and the code of a etsource/datasets/_wizards/
  # folder.
  #
  # By combining values of multiple forms we get a value box, which makes
  # the form data accessible to the ETsource dataset form yml files.
  #
  #
  class SavedWizard < ActiveRecord::Base
    set_table_name 'input_tool_forms'

    # DEBT rename :values to :research_data_bucket and add default: {}
    serialize :values

    # new lambda syntax: equivalent to: lambda{|area_code| ...}
    scope :area_code, -> area_code { where(area_code: area_code) }

    # we can use this to easily invalidate cache data, by adding a timestamp to
    # the cache key.
    def self.last_updated(code)
      where(:area_code => code).maximum('updated_at')
    end

    def research_dataset
      @research_dataset ||= ResearchDataset.new([self])
    end

    def description
      Etsource::Wizard.new(code).description_html
    end

    # DEBT rename :values to :research_data_bucket and add default: {}
    def research_data_bucket
      (values || {})
    end
  end
end
