require 'csv'
##
# Import from Wouters CSV files to a Blueprint or Dataset
#
# == Use:
#   csv_import = CsvImport.new(500, 'ch')
#   # CsvImport expects that there is a folder import/500/ch with all the files
#   blueprint = csv_import.create_blueprint
#   csv_import.create_dataset(blueprint.id, 'ch')
#   csv_import.create_dataset(blueprint.id, 'nl')
#
class CsvImport
  def initialize(version, region_code)
    @version = version
    @region_code = region_code
    @path = @version + "/" + @region_code
  end

  def create_blueprint
    blueprint = nil
    Blueprint.transaction do
      blueprint = Blueprint.create(:graph_version => @version)

      create_blueprint_groups(blueprint)
      create_blueprint_converters(blueprint)
      create_blueprint_converter_group_associations(blueprint)
      create_blueprint_slots(blueprint)
      create_blueprint_links(blueprint)
    end
    blueprint
  end

  def create_dataset(blueprint_id, region_code)
    dataset = nil
    Dataset.transaction do
      dataset = Dataset.create(
        :blueprint_id => blueprint_id,
        :region_code => region_code,
        :area_id => Area.find_by_country(region_code).id)

      create_converter_data(dataset)
      create_link_datas(dataset)
      create_slot_datas(dataset)
      create_time_series(dataset)
    end
    dataset
  end

  private
    
    #
    # Dataset objects
    #
    
    def create_time_series(dataset)
      parse_csv_file "timecurves" do |row|
        attrs = {
          converter_id: row[:converter_id],
          value_type: row[:value_type],
          year: row[:year],
          value: row[:value]
        }
        dataset.time_curve_entries.create!(attrs)
      end
    end

    def create_converter_data(dataset)
      converter_data_attributes = Dataset::ConverterData.column_names
      parse_csv_file "converters" do |row|
        attrs = strip_attributes(row, Dataset::ConverterData)
        dataset.converter_datas.create!(attrs)
      end
    end

    def create_slot_datas(dataset)
      blueprint = dataset.blueprint
      slot_attributes do |attrs|
        slot = blueprint.slots.where(
                :converter_id => attrs[:converter_id], 
                :carrier_id => attrs[:carrier_id],
                :direction => attrs[:direction]
                ).first
        slot_attrs = strip_attributes(attrs, Dataset::SlotData)
        dataset.slot_datas.create!(slot_attrs.merge(:slot_id => slot.id))
      end
    end
    
    def create_link_datas(dataset)
      blueprint = dataset.blueprint
      parse_csv_file "links" do |row|
        blueprint_link = blueprint.links.where(
          :parent_id  => row[:parent_id],
          :child_id   => row[:child_id],
          :carrier_id => row[:carrier_id]
        ).first
        link_attrs = strip_attributes(row, Dataset::LinkData)
        dataset.link_datas.create!(link_attrs.merge(:link_id => blueprint_link.id))
      end
    end
    

    #
    # Blueprint objects
    #

    def create_blueprint_converters(blueprint)
      blueprint_converter_attributes = Converter.column_names
      parse_csv_file "converters" do |row|
        attrs = strip_attributes(row, Converter)
        converter = if converter = Converter.find_by_converter_id(attrs[:converter_id])
          converter.update_attributes(attrs)
          converter
        else
          converter = Converter.create!(attrs)
          converter
        end
        blueprint.converter_records << converter if converter
      end
    end
    
    def create_blueprint_slots(blueprint)
      slot_attributes do |attrs|
        slot_attrs = strip_attributes(attrs, Slot)
        blueprint.slots.create!(slot_attrs)
      end      
    end

    def create_blueprint_links(blueprint)
      parse_csv_file "links" do |row|
        attrs = {
          parent_id: row[:parent_id],
          child_id: row[:child_id],
          carrier_id: row[:carrier_id],
          link_type: row[:link_type]
          # TODO: add these fields with a migration
          # country_specific: row["country_specific"]
          # share: row["share"]
        }
        blueprint.links.create!(attrs)
      end
    end
    
    def create_blueprint_groups(blueprint)
      # the file was previously called definitions
      parse_csv_file "_groups" do |row|
        attrs = {
          group_id: row[:id],
          title: row[:Definition],
          key: row[:Definition_key]
        }
        if group = Group.find_by_group_id(attrs[:group_id])
          group.update_attributes(attrs)
        else
          group = Group.create!(attrs)
        end
      end
    end

    ##
    # Creates the associations between groups and converters.
    # Deletes associations that are not present in the CSV anymore.
    #
    def create_blueprint_converter_group_associations(blueprint)
      groups_blueprints = {}

      parse_csv_file "convertergroups" do |row|
        attrs = {
          group_id: row[:definition_id].to_i,
          converter_id: row[:converter_id].to_i
        }
        
        groups_blueprints[attrs[:group_id]] ||= []
        groups_blueprints[attrs[:group_id]] << attrs[:converter_id]        
      end
      
      groups_blueprints.each do |group_id, converter_ids|
        group = Group.find(group_id)
        group.converter_ids = converter_ids
      end
    end

    #
    # Common methods
    #
    
    # Removes the attributes not present in the db table
    def strip_attributes(attributes, ar_object)
      db_columns = ar_object.column_names.map(&:to_sym)
      attributes.delete_if{|key, value| !db_columns.include?(key) }
    end
    
    def parse_csv_file(file)
      import_path = "import/#{@path}"
      # DEBT: use a better way to select the file
      filename = Dir.entries(import_path).select{|e| e.include?(file.to_s)}.last
      CSV.foreach "#{import_path}/#{filename}", :headers => true, :col_sep => ';', :skip_blanks => true do |row|
        next if row[0].nil? || row[0].empty?
        hash = row.to_hash.symbolize_keys
        # Fix rows
        hash.each_pair do |k, v|
          if v.blank? || v == 'NULL'
            hash[k] = nil
          else
            hash[k] = v.gsub(',', '.')
          end
        end
        yield hash
      end
    end
    
    ##
    # Gets the information from conversion_attributes.
    # Based on conversion data it yields once for an input slot and again if its also a output.
    #
    def slot_attributes
      parse_csv_file 'conversions' do |row|
        # We can get rid of this 1-to-1 mapping as soon as the excel file format is final
        attrs = {
          converter_id: row[:converter_id],
          carrier_id: row[:carrier_id],
          input_country_specific: row[:input_country_specific],
          output_country_specific: row[:output_country_specific],
          input: row[:input],
          output: row[:output]          
        }
        
        if attrs[:input].present?
          attrs[:direction] = 0
          attrs[:conversion] = attrs[:input]
          attrs[:country_specific] = attrs[:input_country_specific]
          yield attrs
        end
        
        if attrs[:output].present?
          attrs[:direction] = 1
          attrs[:conversion] = attrs[:output]
          attrs[:country_specific] = attrs[:output_country_specific]
          yield attrs
        end
      end
    end
end
