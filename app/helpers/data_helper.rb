module DataHelper
  def title_tag_number(value)
    if value.is_a?(Numeric) && value.to_f.finite?
      if value.between?(-1, 1)
        value.to_f # scientific notation
      else
        number_with_delimiter value        
      end
    end
  end

  def notice_message
    capture_haml do
      if flash[:notice]
        haml_tag '#notice', flash[:notice]
      end
    end
  end

  def result_fields(present, future, attr_name = nil, &block)
    if block_given?
      present_value, future_value = nil, nil
      haml_tag :td do
        present_value = yield(present)
        haml_concat auto_number(present_value)
      end
      haml_tag :td do
        future_value = yield(future)
        haml_concat auto_number(future_value)
      end
      change_field(present_value, future_value)
    else
      present_value = present.send(attr_name)
      future_value  = future.send(attr_name)

      haml_tag :td, auto_number(present_value), :title => title_tag_number(present_value)
      haml_tag :td, auto_number(future_value), :title => title_tag_number(future_value)

      change_field(present_value, future_value)
    end
  rescue => e
    haml_tag :td, :colspan => 2 do
      haml_concat "ERROR (#{e})"
    end
  end

  def change_field(present_value, future_value)
    haml_tag :'td.change' do
      if future_value == 0.0 and present_value == 0.0
        haml_concat '' 
      else
        haml_concat "#{(((future_value / present_value) - 1) * 100).to_i}%" rescue '-'
      end
    end
  end
  
  def breadcrumb(x)
    @_breadcrumbs ||= []
    @_breadcrumbs << x
  end
  
  def breadcrumbs
    @_breadcrumbs ||= []
  end
  
  # Autocomplete data caching
  # The various _search_box partials make use of these methods

  def gqueries_autocomplete_map_cache
    Rails.cache.fetch "gqueries_autocomplete_map_cache" do
      loader.gqueries.sort_by(&:key).map do |gquery|
        {label: gquery.key, url: data_gquery_path(:id => gquery.key)}
      end.to_json
    end
  end
  
  def inputs_autocomplete_map_cache
    Rails.cache.fetch "inputs_autocomplete_map_cache" do
      Input.all.map {|a| {label: a.key, url: data_input_path(:id => a.id)} }.to_json
    end
  end
  
  def converters_autocomplete_map_cache
    Rails.cache.fetch "converters_autocomplete_map_cache" do
      converters.sort_by(&:full_key).map {|a| {label: a.full_key.to_s, url: data_converter_path(:id => a)} }.to_json
    end
  end
  
  def carriers_autocomplete_map_cache
    Rails.cache.fetch "carriers_autocomplete_map_cache" do
      carriers.sort_by(&:key).map {|a| {label: a.key, url: data_carrier_path(:id => a)} }.to_json
    end
  end
end