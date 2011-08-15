# == Schema Information
#
# Table name: query_table_cells
#
#  id             :integer(4)      not null, primary key
#  query_table_id :integer(4)
#  row            :integer(4)
#  column         :integer(4)
#  name           :string(255)
#  gquery         :text
#  created_at     :datetime
#  updated_at     :datetime
#

class QueryTableCell < ActiveRecord::Base
  belongs_to :query_table
  validates_uniqueness_of :column, :scope => [:row, :query_table_id]

  def result
    if name.present?
      name
    else
      begin
        result = Current.gql.query(Gql::QueryInterface::Preparser.clean(gquery))
        if result.is_a?(Numeric)
          result
        else
          result.present_value
        end
      rescue
        "Error"
      end
    end
  end
end

