module InputTool
  # Forms keep the input data of researchers temporarly in the database.
  # They are assigned country and the code of a etsource/datasets/_forms/
  # folder.
  #
  # By combining values of multiple forms we get a value box, which makes
  # the form data accessible to the ETsource dataset form yml files.
  #
  #
  class Form < ActiveRecord::Base
    set_table_name 'input_tool_forms'


    # we can use this to easily invalidate cache data, by adding a timestamp to
    # the cache key.
    def self.last_updated(code)
      InputTool::Form.where(:area_code => code).maximum('updated_at')
    end

    def value_box
      @value_box ||= ValueBox.new([self])
    end

    def input_form
      Etsource::Forms.new.form_for(code)
    end

    def description
      Etsource::Forms.new.description_for(code)
    end

    def dataset_values
      self[:values] ||= YAML::dump({})
      YAML::load(self[:values]).with_indifferent_access
    end
  end
end
