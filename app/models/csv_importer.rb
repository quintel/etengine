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

    expanded_zip_file_root = expand_zip_file(version_path)
    countries = get_countries_from_expanded_archive(expanded_zip_file_root)

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
  
  private
    
    # Expands the zip file in a folder
    # Returns the path of the folder with the zip contents as a string
    #
    def expand_zip_file(to_folder)
      Zip::ZipFile.open(zip_file.tempfile) do |zip_item|
        zip_item.each do |f|
          f_path = File.join(to_folder, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_item.extract(f, f_path) unless File.exist?(f_path)
        end
      end  
      
      # The new zip format has an extra nested directory though!
      # import/v12345/v12345/nl/*.csv
      # => import/v12345/v12345
      expanded_zip_file_root = "#{to_folder}/" + Dir.entries(to_folder).find{|x| !x.match /\./}          
    end
    
    # Returns an array with the countries defined in the zip folder
    #
    def get_countries_from_expanded_archive(folder)
      # excludes dot directories and the silly __MACOSX folder
      Dir.entries(folder).reject{|p| p.include?('MACOS')}.select{|dir|
        File.directory?("#{folder}/#{dir}") and !dir.match(/^\./)
      }
    end
end
