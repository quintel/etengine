module JavascriptHelper

  # Convert an Array of objects/values to a javascript parameter list
  #
  # e.g. 
  #   js_params [12, 'foo', nil]
  #   => "12, 'foo', null" 
  # 
  # @param [Array]
  # @return [String]
  #
  def js_params(params)
    [params].flatten.map do |param|
      param.nil? ? 'null' : param.inspect
    end.join(', ')
  end
  
  def init_etm_javascript_framework
    javascript_tag "var ETM = new MainController();"
  end

  def create_input_element(input_element)
    input_element_id = dom_id(input_element)
    "ETM.inputElementsController.addInputElement(new InputElement(%s.input_element), {'element':$('#%s')});" % [input_element.to_json, input_element_id]
  end
  
  def update_input_element(input_element)
    script = "var a = ETM.inputElementsController.getInputElementById('%s');" % input_element.id
    script << "if(a) a.updateAttributes(%s.input_element); else console.log('Updating input element with id: %s, but not on page');" % [input_element.to_json, input_element.id]
    script.html_safe
  end
  
  
  def update_constraint(constraint)
    ''
  end



end