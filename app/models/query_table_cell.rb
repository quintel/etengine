class QueryTableCell < ApplicationRecord
  belongs_to :query_table
  validates_uniqueness_of :column, :scope => [:row, :query_table_id]

  scope :embedded_gql_contains, lambda{|search| where("gquery LIKE :q", :q => "%#{search}%") }

  # @param gql Gql::Gql
  def result(gql)
    if name.present?
      name
    else
      begin
        result = gql.query(gquery)
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
