module EtsourceHelper
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
      :value => @form.value_box.get(@form.code, *keys), 
      :step  => 0.1
    }.merge(opts)
    
    capture_haml do
      haml_tag :input, opts
    end
  end
end