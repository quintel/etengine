module Etsource
  class Inputs
    def initialize(etsource)
      @etsource = etsource
    end

    def import!
      # Do not delete inputs because input ids are important and referenced by et-model
      # seb: I will delete all the ids that are not present in etsource at the end of import.
      import
    end

    def export
      base_dir = "#{@etsource.base_dir}/inputs"

      FileUtils.mkdir_p(base_dir)
      Input.find_each do |input|
        attrs = input.attributes
        attrs.delete('created_at')
        attrs.delete('updated_at')
        File.open("#{base_dir}/#{input.key}.yml", 'w') do |f|
          f << YAML::dump(attrs)
        end
      end
    end

    # ATTENTION bug hunters:
    # If you get  Mysql2::Error: Duplicate entry '549' for key 'PRIMARY':
    # upon importing inputs, you might want to comment #input.force_id()
    # and import a few times, until the mysql auto_increment ID is high enough
    #
    def import
      base_dir = "#{@etsource.export_dir}/inputs"

      ids = []
      Dir.glob("#{base_dir}/**/*.yml").each do |f|
        attributes = YAML::load_file(f)
        id = attributes.delete('id')
        ids << id
        begin
          input = Input.find(id)
          input.update_attributes(attributes)
        rescue ActiveRecord::RecordNotFound
          Rails.logger.debug "*** ETSource::Inputs#import: Created new Input"
          input = Input.find_by_key(attributes['key'])
          input.update_attributes(attributes) if input
          input ||= Input.create!(attributes)
          input.force_id(id)
        end
      end
      Input.where(["id NOT IN (?)", ids]).each(&:destroy)
    end
  end
end
