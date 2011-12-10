module InputTool
  class Form < ActiveRecord::Base
    set_table_name 'input_tool_forms'

    def value_box
      @value_box = ValueBox.new([self])
    end

    def input_form
      Etsource::Forms.new.form_for(code)
    end

    def description
      Etsource::Forms.new.description_for(code)
    end

    def dataset_values
      YAML::load(values).with_indifferent_access
    end
  end
end
