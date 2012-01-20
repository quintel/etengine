module EtsourceHelper
  def loader
    Etsource::Loader.instance
  end

  def wizard_config
    raise "Trying to access wizard_config. But @wizard is not defined." unless @wizard
    @wizard.config
  end

  def number_field(*args)
    if !defined?(@form) && @form.is_a?(InputTool::Form)
      raise "Instance variable @form should be assigned a InputTool::Form object, but is: #{@form.inspect}" 
    end
    opts = args.extract_options!
    keys = args
    name = @form.code.to_s + keys.map{|k| "[#{k}]"}.join('')

    opts = {
      :type  => "number", 
      :name  => name, 
      :value => @form.research_dataset.get(@form.code, *keys), 
      :step  => 0.1
    }.merge(opts)
    
    capture_haml do
      haml_tag :'input.span2', opts
      if opts[:disabled] == true
        haml_tag :'input.span2', opts.merge(:type => 'hidden', :disabled => false)
      end
    end
  end
end