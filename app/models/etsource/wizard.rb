# Wizards are used for the input module. 
# The wizards itself are not area-specific. But the values that researchers enter into
# forms are country-specific. With the values entered into the forms we can update
# the dataset. It is not yet clear where we want to store the data entered into the Wizards.
#
#    Etsource::Wizard.codes
#    => ['area_data', 'households']
#
#    wizard = Etsource::Wizard.new('households')
#    wizard.list # => [car_technology_shares, ...]
#    wizard.form_template_file # => template for etengine to render
#    wizard.config # config.yml of wizard that runs both in form and transformer
#
#
module Etsource
  class Wizard
    attr_accessor :file_name

    # file_name is really just the path _wizards/.../
    def initialize(file_name, etsource = Etsource::Base.instance)
      @file_name = file_name
      @etsource = etsource
    end

    def form_template_file
      Dir.glob([base_dir,file_name,'form.html.*'].join('/')).first
    end

    def description_template_file
      [base_dir,file_name,"description.html.erb"].join('/')
    end

    def compiled_transformer_file_content(country)
      f = compiled_transformer_file(country)
      if File.exists?(f)
        File.read(f)
      else
        '(no file)'
      end
    end

    def config
      if config_file
        @config ||= YAML::load(ERB.new(File.read(config_file)).result).with_indifferent_access
      else
        @config ||= {}
      end
    end

    def config_file
      Dir.glob([base_dir,file_name,'config.yml'].join('/')).first
    end

    def description_html
      # prevents param hacking
      raise "No form found for #{file_name}!" unless list.include?(file_name)
      File.read(description_template_file).html_safe rescue ''
    end

    def self.codes
      Dir.glob("#{base_dir}/*").select{|d| File.directory?(d)}.map{|d| d.split("/").last }
    end

  #########
  protected
  #########

    def compiled_transformer_file(country)
      "#{@etsource.base_dir}/compiled/#{country}/_wizards/#{file_name}/transformer.yml"
    end
    
    # DEBT: refactor this two methods
    def base_dir
      "#{@etsource.base_dir}/datasets/_wizards"
    end
    
    def self.base_dir
      "#{Etsource::Base.instance.base_dir}/datasets/_wizards"
    end
  end
end