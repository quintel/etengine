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

  ##
  #
  #
  def initialize(version, region_code)
    @version = version
    @region_code = region_code
    @path = @version+"/"+@region_code
  end

  ##
  # Creates a Blueprint
  #
  # return [Blueprint]
  #
  def create_blueprint
    blueprint = nil
    Blueprint.transaction do
      blueprint = Blueprint.create(:graph_version => @version)

      create_blueprint_groups(blueprint)
      create_blueprint_converters(blueprint)
      create_blueprint_converter_group_associations(blueprint)

      slot_attributes do |attributes|
        attributes = strip_attributes(attributes, Slot)
        blueprint.slots.create!(attributes)
      end

      link_attributes do |attributes|
        attributes = strip_attributes(attributes, Link)
        blueprint.links.create!(attributes)
      end
    end
    blueprint
  end

  ##
  # Creates a Dataset for the given blueprint_id and region_code
  #
  # return [Dataset]
  #
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
  def create_time_series(dataset)
    time_curve_attributes do |attributes|
      attributes = strip_attributes(attributes, TimeCurveEntry)
      dataset.time_curve_entries.create!(attributes)
    end
  end

  def create_converter_data(dataset)
    converter_attributes do |attributes|
      attributes = strip_attributes(attributes, ConverterData)
      dataset.converter_datas.create!(attributes)
    end
  end

  def create_link_datas(dataset)
    blueprint = dataset.blueprint

    link_attributes do |attributes|
      blueprint_link = blueprint.links.find(:first,
        :conditions => [:parent_id, :child_id, :carrier_id].inject({}) {|hsh,key|
          hsh.merge key => attributes[key]
        }
      )

      attributes = strip_attributes(attributes, LinkData)
      dataset.link_datas.create!(attributes.merge!(:link_id => blueprint_link.id))
    end
  end

  def create_slot_datas(dataset)
    blueprint = dataset.blueprint

    slot_attributes do |attributes|
      slot = blueprint.slots.find(:first,
        :conditions => [:converter_id, :carrier_id, :direction].inject({}) {|hsh,key|
          hsh.merge key => attributes[key]
        }
      )

      attributes = strip_attributes(attributes, SlotData)
      dataset.slot_datas.create!(attributes.merge!(:slot_id => slot.id))
    end
  end

  def create_blueprint_converters(blueprint)
    converter_attributes do |attributes|
      converter = if converter = Converter.find_by_converter_id(attributes[:converter_id])
        converter.update_attributes(strip_attributes(attributes, Converter))
        converter
      else
        converter = Converter.create!(strip_attributes(attributes, Converter))
        puts "New Converter: #{converter}"
        converter
      end
      blueprint.converter_records << converter if converter
    end
  end

  ##
  # @return [Array<Group>]
  #
  def create_blueprint_groups(blueprint)
    group_attributes do |attributes|
      if group = Group.find_by_group_id(attributes[:group_id])
        group.update_attributes(attributes)
      else
        group = Group.create!(strip_attributes(attributes, Group))
        puts "New Group: #{group}"
        group
      end
    end
  end

  ##
  # Creates the associations between groups and converters.
  # Deletes associations that are not present in the CSV anymore.
  #
  def create_blueprint_converter_group_associations(blueprint)
    groups_blueprints = {}
    groups do |attributes|
      groups_blueprints[attributes[:group_id]] ||= []
      groups_blueprints[attributes[:group_id]] << attributes[:converter_id]
    end

    groups_blueprints.each do |group_id, converter_ids|
      group = Group.find(group_id)
      group.converter_ids = converter_ids
    end
    nil
  end

  # TODO refactor (seb 2010-10-11)
  def load_csv(model_name, remove_header = true)
    import_path = "import/#{@path}"
    file = Dir.entries(import_path).select{|e| e.include?(model_name.to_s)}.first || raise("File not found for #{model_name} in #{import_path}")

    str = File.read(import_path+"/"+file)
    if str.include?("\r\n")
      line_separator = "\r\n"
    elsif str.include?("\r")
      line_separator = "\r"
    else
      line_separator = "\n"
    end
    lines = str.split(line_separator)
    separator = ',' if lines.first.include?(',')
    separator = ';' if lines.first.include?(';')
    lines = lines[1..-1] if remove_header

    lines.map{|line| "#{line} ".split(separator).map(&:strip)}
  end

  def fix_row(row)
    row.map do |cell|
      cell = cell.gsub(',','.')
      cell = nil if cell.empty? or cell == 'NULL'
      cell
    end
  end

  def group_attributes(&block)
    load_csv(:definitions).each do |row|
      next if row.first.blank?
      row = fix_row(row)
      group_attributes = {
        :group_id => row[0],
        :title => row[1],
        :key => row[2]
      }

      yield(group_attributes)
    end# :carrier
  end

  def converter_attributes(&block)
    rows = load_csv(:converter, false)
    header = rows.first.map{|h| h.to_sym}
    attribute_names = [Converter, ConverterData].map(&:column_names).flatten.map(&:to_sym).select{|key| header.index(key) }
    rows[1..-1].each do |row|
      row = fix_row(row)
      next if row.first.blank?
      # todo remove the demand => preset_demand mess
      converter_attributes = attribute_names.inject({}) {|hsh,key| hsh.merge key => row[ header.index(key) ] }
      yield(converter_attributes)
    end
  end

  def time_curve_attributes(&block)
    rows = load_csv(:timecurves, false)
    header = rows.first.map{|h| h.to_sym}
    attribute_names = TimeCurveEntry.column_names.map(&:to_sym).select{|key| header.index(key) }
    rows[1..-1].each do |row|
      row = fix_row(row)
      next if row.first.blank?
      time_curve_attributes = attribute_names.inject({}) {|hsh,key| hsh.merge key => row[ header.index(key) ] }
      yield(time_curve_attributes)
    end
  end

  def groups(&block)
    load_csv(:group).each do |row|
      next if row.first.blank?
      group_id, converter_id = fix_row(row).map(&:to_i)
      attributes = {:group_id => group_id, :converter_id => converter_id}
      yield(attributes)
    end
  end

  ##
  # Gets the information from conversion_attributes.
  # Based on conversion data it yields once for an input slot and again if its also a output.
  #
  def slot_attributes(&block)
    conversion_attributes do |attributes|
      if attributes[:input].present?
        yield(attributes.merge(:direction => 0, :conversion => attributes[:input]))
      end
      if attributes[:output].present?
        yield(attributes.merge(:direction => 1, :conversion => attributes[:output]))
      end
    end
  end

  ##
  # Not used directly, but by slot_attributes
  #
  def conversion_attributes(&block)
    load_csv(:conversion).each do |row|
      next if row.first.blank?
      row = fix_row(row[0...4])
      if row.length == 4 and row[0].present?
        attributes = {
          :converter_id => row[0],
          :carrier_id => row[1],
          :input => row[2],
          :output => row[3]
        }
        yield(attributes)
      end
    end
  end


  def link_attributes(&block)
    load_csv(:links).each do |row|
      next if row.first.blank?
      row = fix_row(row[0...5])
      if row.length >= 5 and row[0].strip.present?
        attributes = {
          :parent_id => row[0],
          :child_id => row[1],
          :carrier_id => row[2],
          :share => row[3],
          :link_type => row[4]
        }
        yield(attributes)
      end
    end
  end

  ##
  # Removes key/values of a hash, that do not exist in a ActiveRecord model
  #
  # @param hs [Hash]
  # @param ar_class [#colum_names]
  #
  def strip_attributes(hsh, ar_class)
    hsh.delete_if{|k,v| !ar_class.column_names.map(&:to_sym).include?(k)}
  end
end
