# This class takes care of the entire zip import process
# It uses many ActiveModel mixins for convenience

require 'zip/zip'

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
  
  # Do everything
  def process!
    version_path = "import/#{version}"

    Zip::ZipFile.open(zip_file.tempfile) do |zip_item|
      zip_item.each do |f|
        f_path = File.join(version_path, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_item.extract(f, f_path) unless File.exist?(f_path)
      end
    end

    countries = Dir.entries(version_path).reject{|p| p.include?('MACOS')}.select{|country_dir|
      # check that file is directory. excluding: "." and ".."
      File.directory?("#{version_path}/#{country_dir}") and !country_dir.match(/^\./)
    }

    csv_import = CsvImport.new(version, countries.first)
    blueprint = csv_import.create_blueprint
    blueprint.update_attribute :description, description

    countries.each do |country|
      csv_import = CsvImport.new(version, country)
      dataset = csv_import.create_dataset(blueprint.id, country)
      Graph.create :blueprint_id => blueprint.id, :dataset_id => dataset.id
    end
    
  end
end
