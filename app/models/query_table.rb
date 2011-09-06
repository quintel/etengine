# == Schema Information
#
# Table name: query_tables
#
#  id           :integer(4)      not null, primary key
#  name         :string(255)
#  description  :text
#  row_count    :integer(4)
#  column_count :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

class QueryTable < ActiveRecord::Base
  has_many :query_table_cells, :dependent => :delete_all

  default_value_for :column_count, 1
  default_value_for :row_count, 1

  validates_presence_of :column_count
  validates_numericality_of :column_count

  validates_presence_of :row_count
  validates_numericality_of :row_count


  def cell(row, column)
    query_table_cells.detect{|cell| cell.row == row and cell.column == column}
  end

end
