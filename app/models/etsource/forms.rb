# Forms are used for the input module. 
# The forms itself is not area-specific. But the values that researchers enter into
# forms are country-specific. With the values entered into the forms we can update
# the dataset.
# It is not yet clear where we want to store the data entered into Forms.
#
#    forms = Etsource::Forms.new
#    forms.list # => [car_technology_shares, ...]
#    forms.form_for(forms.list.first) # => some html
#
#
module Etsource
  class Forms
    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
    end

    def form_template_for(file_name)
      [base_dir,file_name,"form.html.erb"].join('/')
    end


    def description_template_for(file_name)
      [base_dir,file_name,"description.html.erb"].join('/')
    end

    def form_for(file_name)
      # prevents param hacking
      raise "No form found for #{file_name}!" unless list.include?(file_name)
      File.read(form_template_for(file_name)).html_safe
    end

    def description_for(file_name)
      # prevents param hacking
      raise "No form found for #{file_name}!" unless list.include?(file_name)
      File.read(description_template_for(file_name)).html_safe rescue ''
    end

    def list
      @forms ||= Dir.glob("#{base_dir}/*").select{|d| File.directory?(d)}.map{|d| d.split("/").last }
    end

  #########
  protected
  #########

    def base_dir
      "#{@etsource.base_dir}/datasets/forms"
    end
  end
end