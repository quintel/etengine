module InputTool
  class ValueBox
    
    def initialize(forms)
      @values = forms.all.inject({}) {|hsh,f| hsh.merge f.code => f.dataset_values}
    end

    def self.area(code)
      new(InputTool::Form.where(:area_code => code))
    end

    def get_binding
      binding
    end

    def get(*args)
      options = args.extract_options!

      value = @values
      args.each do |key|
        value = value.with_indifferent_access[key]
      end
      value.to_f
    rescue
      options[:default]
    end
  end
end