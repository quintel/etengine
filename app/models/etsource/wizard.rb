# Wizards are used for the input module. 
# The wizards itself are not area-specific. But the values that researchers enter into
# forms are country-specific. With the values entered into the forms we can update
# the dataset. It is not yet clear where we want to store the data entered into the Wizards.
#
#    wizards = Etsource::Wizard.new
#    wizards.list # => [car_technology_shares, ...]
#    wizards.form_for(wizards.list.first) # => some html
#
#
module Etsource
  class Wizard
    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
    end

    def form_template_for(file_name)
      Dir.glob([base_dir,file_name,'form.html.*'].join('/')).first
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
      @wizards ||= Dir.glob("#{base_dir}/*").select{|d| File.directory?(d)}.map{|d| d.split("/").last }
    end

  #########
  protected
  #########

    def base_dir
      "#{@etsource.base_dir}/datasets/_wizards"
    end
  end
end