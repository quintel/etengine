# This class takes care of the entire zip import process
# It uses many ActiveModel mixins for convenience

class CsvImporter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :version, :description, :zip_file

  validates :version, :presence => true
  validates :zip_file, :presence => true

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  # This object won't be stored in the database
  def persisted?
    false
  end
end
