module Etsource
  class Scenario
    def initialize
      @etsource = Etsource::Base.instance
    end

    def import!
      # Do not delete scenarios because scenario ids are important and referenced by et-model
      import
    end

    def import
      base_dir = "#{@etsource.export_dir}/scenarios"

      ids = []
      Dir.glob("#{base_dir}/*.yml").each do |f|
        attributes = YAML::load_file(f).with_indifferent_access
        id = attributes.delete('id')
        ids << id
        begin
          scenario = ::Scenario.find(id)
          scenario.update_attributes(attributes)
        rescue ActiveRecord::RecordNotFound
          Rails.logger.debug "*** ETSource::::Scenarios#import: Created new ::Scenario"
          scenario = ::Scenario.create!(attributes)
          scenario.force_id(id)
        end
      end
    end
  end
end
