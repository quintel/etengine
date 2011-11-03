# This class takes care of the entire zip import process
# It uses many ActiveModel mixins for convenience

require 'zip/zip'
require 'fileutils'

class CsvImporter
  IMPORT_FOLDER = "import"

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :version, :description, :zip_file

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
  #
  def process!
    # The top directory name will be used as version name
    self.version = expand_zip_file_and_get_version_name

    countries = get_countries_from_expanded_archive(expanded_zip_root)

    csv_import = CsvImport.new(version, countries.first, expanded_zip_root)
    blueprint = csv_import.create_blueprint
    blueprint.update_attribute :description, description

    countries.each do |country|
      csv_import = CsvImport.new(version, country, expanded_zip_root)
      dataset = csv_import.create_dataset(blueprint.id, country)
      Graph.create :blueprint_id => blueprint.id, :dataset_id => dataset.id
    end
    true
  ensure
    cleanup!
  end
  
  private
    
    # Expands the zip file and returns the name of the top folder
    #
    def expand_zip_file_and_get_version_name
      Zip::ZipFile.open(zip_file.tempfile) do |zip_item|
        zip_item.each do |f|
          f_path = File.join(IMPORT_FOLDER, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_item.extract(f, f_path) unless File.exist?(f_path)
        end
      end  
      
      # The container folder (that should be used as version name) should be the only directory
      # inside IMPORT_FOLDER
      Dir.entries(IMPORT_FOLDER).find{|x| !x.match /\./}
    end
    
    # Returns an array with the countries defined in the zip folder
    #
    def get_countries_from_expanded_archive(folder)
      # excludes dot directories and the silly __MACOSX folder
      Dir.entries(folder).reject{|p| p.include?('MACOS')}.select{|dir|
        File.directory?("#{folder}/#{dir}") and !dir.match(/^\./)
      }
    end

    # Returns the location of the expanded zip file
    #
    def expanded_zip_root
      "#{IMPORT_FOLDER}/#{version}"
    end

    # Deletes the expanded zip
    #
    def cleanup!
      if File.directory?(expanded_zip_root)
        FileUtils.rmtree(expanded_zip_root)
      end
    end
end
