require 'csv'
##
# Import from Wouters CSV files to a Blueprint or Dataset
#
# == Use:
#   csv_import = CsvImport.new(500, 'ch', 'import/v12345')
#   # CsvImport expects that there is a folder import/v12345/500/ch with all the files
#   blueprint = csv_import.create_blueprint
#   csv_import.create_dataset(blueprint.id, 'ch')
#   csv_import.create_dataset(blueprint.id, 'nl')
#
class CsvImport
  def initialize(version, region_code, zip_root)
    # debugger
    @version = version
    @region_code = region_code
    @path = "#{zip_root}/#{@region_code}"
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
      
      valid, errors = blueprint.validate_topology!
      raise errors.join(", ") unless valid
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
          link_type: row[:link_type],
          country_specific: row[:country_specific]
        }
        blueprint.links.create!(attrs)
      end
    end
    
    def create_blueprint_groups(blueprint)
      # the file was previously called definitions
      parse_csv_file "groups" do |row|
        attrs = {
          group_id: row[:id],
          title: row[:title],
          key: row[:key]
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
    #
    def strip_attributes(attributes, ar_object)
      db_columns = ar_object.column_names.map(&:to_sym)
      attributes.delete_if{|key, value| !db_columns.include?(key) }
    end
    
    # Yields a block with a hash of the items for each CSV file row
    #
    def parse_csv_file(file)
      filename = "#{@path}/#{file}.csv"
      lines = File.readlines filename
      # Excel CSV export sucks. Lots of empty records or, worse, empty lines with a trailing \r\r\n
      valid_lines = lines.map{|l| l.gsub /[\r\n]/, ''}.join("\n")
      CSV.parse valid_lines, :headers => true, :col_sep => ';', :skip_blanks => true, :row_sep => :auto do |row|
        next if row[0].nil? || row[0].empty?
        hash = row.to_hash.symbolize_keys
        hash.each_pair {|k, v| hash[k] = fix_csv_cell(v) }
        yield hash
      end
    end
    
    # Convert excel file export as needed
    #
    def fix_csv_cell(s)
      if s.blank? || s == 'NULL'
        nil
      elsif s.is_a?(String)
        s.gsub(',', '.').strip
      else
        s
      end
    end
    
    # Gets the information from conversion_attributes. Unlike the other CSV files, sometimes
    # we have to process the row twice because the a conversion might be bidirectional: once
    # for an input slot and again if it's also an output.
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
          yield attrs.merge(:direction => 0,
                            :conversion => attrs[:input],
                            :country_specific => attrs[:input_country_specific])
        end
        
        if attrs[:output].present?
          yield attrs.merge(:direction => 1,
                            :conversion => attrs[:output],
                            :country_specific => attrs[:output_country_specific])
        end
      end
    end
end
