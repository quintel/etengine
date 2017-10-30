class QueryTable < ApplicationRecord
  has_many :query_table_cells, :dependent => :delete_all

  validates_presence_of :column_count
  validates_numericality_of :column_count

  validates_presence_of :row_count
  validates_numericality_of :row_count


  def cell(row, column)
    query_table_cells.detect{|cell| cell.row == row and cell.column == column}
  end

end
