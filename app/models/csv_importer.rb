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
  # DEBT: cleanup the zip file extraction and content parsing
  #
  def process!
    version_path = "import/#{version}"

    # Expand the zip file into import/version
    #
    Zip::ZipFile.open(zip_file.tempfile) do |zip_item|
      zip_item.each do |f|
        f_path = File.join(version_path, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_item.extract(f, f_path) unless File.exist?(f_path)
      end
    end

    # The new zip format has an extra nested directory though!
    # import/v12345/v12345/nl/*.csv
    # => import/v12345/v12345
    expanded_zip_file_root = "#{version_path}/" + Dir.entries(version_path).find{|x| !x.match /\./}

    # Zip files created on the mac have the silly __MACOSX folder, that should
    # better be ignored
    countries = Dir.entries(expanded_zip_file_root).reject{|p| p.include?('MACOS')}.select{|country_dir|
      # check that file is directory. excluding: "." and ".."
      File.directory?("#{expanded_zip_file_root}/#{country_dir}") and !country_dir.match(/^\./)
    }

    csv_import = CsvImport.new(version, countries.first, expanded_zip_file_root)
    blueprint = csv_import.create_blueprint
    blueprint.update_attribute :description, description

    countries.each do |country|
      csv_import = CsvImport.new(version, country, expanded_zip_file_root)
      dataset = csv_import.create_dataset(blueprint.id, country)
      Graph.create :blueprint_id => blueprint.id, :dataset_id => dataset.id
    end
    true
  end
end
