module GraphvizHelper
  def graphviz_attribute_selector
    out = select_tag 'period', options_for_select(['future', 'present']), :onchange => 'GRAPH.show_attribute_values()'
    out += select_tag 'attribute', options_for_select([]), :onchange => 'GRAPH.show_attribute_values()'
    out += link_to 'Show', 'javascript:GRAPH.show_attribute_values()'
    out
  end

  def graphviz_toggle_sectors
    out = select_tag 'selected', options_for_select([*@gql.present_graph.sectors, 'all'])
    out += link_to 'show', 'javascript:GRAPH.show_selected()'
    out += ", "
    out += link_to 'hide', 'javascript:GRAPH.hide_selected()'
    out += "(to only show one sector, hide 'all' first, then show 'sector')"
    out
  end

end