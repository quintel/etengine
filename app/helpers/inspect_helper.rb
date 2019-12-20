module InspectHelper
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

  def result_fields(present, future, attr_name = nil)
    present_value = present.instance_eval(attr_name.to_s)
    future_value  = future.instance_eval(attr_name.to_s)

    haml_tag :td, auto_number(present_value), :title => title_tag_number(present_value)
    haml_tag :td, auto_number(future_value), :title => title_tag_number(future_value)

    change_field(present_value, future_value)
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
        {label: gquery.key, url: inspect_gquery_path(:id => gquery.key)}
      end.to_json
    end
  end

  def inputs_autocomplete_map_cache
    Rails.cache.fetch "inputs_autocomplete_map_cache" do
      Input.all.map {|a| {label: a.key, url: inspect_input_path(:id => a.id)} }.to_json
    end
  end

  def converters_autocomplete_map_cache
    Rails.cache.fetch "converters_autocomplete_map_cache" do
      converters.sort_by(&:key).map do |a|
        {label: a.key, url: inspect_converter_path(:id => a)}
      end.to_json
    end
  end

  def carriers_autocomplete_map_cache
    Rails.cache.fetch "carriers_autocomplete_map_cache" do
      carriers.sort_by(&:key).map {|a| {label: a.key, url: inspect_carrier_path(:id => a)} }.to_json
    end
  end

  # Since the group table has been dropped we need to fetch the list from ETSource
  def converter_groups
    Rails.cache.fetch "converter_group_list" do
      initialize_gql unless @gql
      @gql.present_graph.converters.map{|c| c.groups}.flatten.sort.uniq
    end
  end

  # Given a scenario or preset ID, creates an HTML link to display it.
  #
  # Presets are linked to the AD file on ETEngine, using the same Git
  # reference as is currently loaded in ETE. Scenarios are linked to the "view
  # scenario page" in the admin UI.
  #
  # Returns a string.
  def preset_or_scenario_link(id)
    if preset = Preset.get(id)
      git_ref = Etsource::Base.instance.get_latest_import_sha
      atl_doc = Atlas::Preset.all.find { |p| p.id == preset.id }

      if atl_doc
        link = "https://github.com/quintel/etsource/blob/" +
          "#{ git_ref }/data/" +
          "#{ atl_doc.path.relative_path_from(Atlas.data_dir) }"

        name = atl_doc.path.relative_path_from(Atlas::Preset.directory).to_s
      else
        link = nil
        name = id.to_s
      end
    else
      link = inspect_scenario_path(id: id)
      name = id.to_s
    end

    link ? link_to(name, link) : name
  end

  def link_to_node_file(converter)
    doc = Atlas::Node.find(converter.key)
    rev = Etsource::Base.instance.get_latest_import_sha

    rev = 'HEAD' if rev.blank?

    "https://github.com/quintel/etsource/blob/#{ rev }/" \
    "#{ doc.path.relative_path_from(Atlas.data_dir) }"
  end

  def link_to_edge_file(link)
    key = Atlas::Edge.key(
      link.rgt_converter.key, link.lft_converter.key, link.carrier.key)

    doc = Atlas::Edge.find(key)
    rev = Etsource::Base.instance.get_latest_import_sha

    rev = 'HEAD' if rev.blank?

    "https://github.com/quintel/etsource/blob/#{ rev }/" \
    "#{ doc.path.relative_path_from(Atlas.data_dir) }"
  end

  def kms_slot?(slot)
    slot.carrier.key.to_s.match(/_kms\b/)
  end

  def converter_flow(converter, direction)
    slots = converter.public_send(direction == :inputs ? :inputs : :outputs)

    return nil if slots.none?

    slots.sum do |slot|
      if slot.links.any?
        slot.external_value
      else
        # Fallback for left-most or right-most slots with no links.
        slot.converter.demand * slot.conversion
      end
    end
  end

  def format_query_performance(time)
    css_class = %w[timing]

    if time > 0.1
      css_class.push('error')
    elsif time > 0.01
      css_class.push('warning')
    end

    haml_tag("span.#{css_class.join('.')}") do
      haml_concat((time * 1000).round(2))
      haml_concat(' ms')
    end
  end

  # Public: Returns if a converter "object attribute" (`merit_order`, `fever`,
  # etc) identifies another converter.
  #
  # Returns true or false.
  def object_attribute_is_converter?(name)
    %i[alias_of delegate].include?(name)
  end

  # Public: Returns the scenario flexibility or heat network order as a string
  # with each option on a newline.
  def user_sortable_list(sortable)
    sortable.order.join("\n")
  end
end
