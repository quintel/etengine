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

end