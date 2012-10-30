# On drawing boxes and links:
# SVG determines z-index of elements by its creation order.

class @Graph
  updated_coordinates: {}
  SNAPPABLE_GRID_SIZE: 10
  GRID_STEP_SIZE: 800
  GRID_X_SIZE: 8000
  GRID_Y_SIZE: 13000

  link_styles:
    constant  : ''
    share     : '-'
    flexible  : '. '
    dependent : '--..'

  constructor: (width = @GRID_X_SIZE, height = @GRID_Y_SIZE) ->
    @width = width
    @height = height
    @r = Raphael("canvas", width, height)
    @selected = []
    @converters = {}
    @links = []

  # Draws the graph
  #
  draw: =>
    @drawGrid()
    link.draw() for link in @links
    for key, converter of @converters
      converter.draw()
    link.adjust_to_converter() for link in @links

  enableDragging: ->
    converter.addDragEventListeners() for key, converter of @converters

  # Draw the grid.
  #
  drawGrid: =>
    for i in [1..@width] by @GRID_STEP_SIZE
      # M0   1 L10000   1
      # M0 801 L10000 80
      @r.path("M#{i},0L#{i},#{@height}")
        .attr({stroke : '#ccc'})

    for i in [1..@height] by @GRID_STEP_SIZE
      # M1   0 L1   8000
      # M801 0 L801 8000
      @r.path("M0,#{i}L#{@width},#{i}")
        .attr({stroke : '#ccc'})

  show_attribute_values: =>
    for key, c of @converters
      period = $('#period').val()
      attr = $('#attribute').val()
      if data[period]? && data[period][key]? && data[period][key][attr]?
        value = data[period][key][attr]
        c.box.value_node.setAttr('text', value)

  show_selected: ->
    selected_group = $('#selected').val()
    for key, converter of @converters
      if (selected_group == 'all' || converter.sector == selected_group)
        converter.show()

  hide_selected: ->
    selected_group = $('#selected').val()
    for id, converter of @converters
      if (selected_group == 'all' || converter.sector == selected_group)
        converter.hide()

  deselect_all: =>
    for converter in @selected
      converter.converter.unselect()
    return false

  highlight_off_all: =>
    for key, converter of @converters
      converter.highlight_off()
    return false

  mark_all_dirty: =>
    converter.markDirty() for key, converter of @converters

  # { converter_key : {x : 12, y : 23, hidden : true} }
  #
  getUpdatedValues: ->
    converter_position_attrs = {}
    for key, converter of @converters
      if converter.isDirty()
        converter_position_attrs[key] = converter.getAttributes()
    converter_position_attrs

  # drag event handlers
  #
  elements_drag: (elements) ->
    for converter_box in elements
      for link in converter_box.converter.links
        # Highlights in/output converter slots
        link.input_converter.input_slot().attr({fill : '#cc0'})
        link.output_converter.output_slot().attr({fill : '#cc0'})
      b = converter_box # "b" just to make it more readable
      b.ox = if b.type == "rect" then b.attr("x") else b.attr("cx")
      b.oy = if b.type == "rect" then b.attr("y") else b.attr("cy")

  elements_move: (elements,dx,dy) ->
    for converter_box in elements
      converter_box.converter.moveTo(dx,dy)

  elements_up: (elements) ->
    for converter_box in elements
      for link in converter_box.converter.links
        link.input_converter.input_slot().attr({fill : '#fff'})
        link.output_converter.output_slot().attr({fill : '#fff'})
      converter_box.converter.update_position(converter_box.attr('x'), converter_box.attr('y'))

class @Link
  constructor: (args) ->
    [input_key, output_key, color, style] = args
    @color = color
    @style = style
    @output_converter = GRAPH.converters[output_key]
    @input_converter = GRAPH.converters[input_key]

    @output_converter.links.push(this)
    @input_converter.links.push(this)
    @r = GRAPH.r
    GRAPH.links.push(this)

  # Draw the Link.
  # *Warning*: The order of the elements being drawed defines their z-index.
  #            We want the links to appear behind the converter boxes, therefore
  #            call draw() on links first.
  #
  draw: =>
    @shape = @r.connection(@input_converter.input_slot(),
                          @output_converter.output_slot(),
                          @color,
                          @color+'|'+@style)

  output_converter: -> @output_converter

  input_converter: -> @input_converter

  highlight_on: ->
    @shape.bg.attr({stroke : '#f00'})
    @shape.line.attr({stroke : '#f00'})

  highlight_off: ->
    @shape.bg.attr({stroke : @color})
    @shape.line.attr({stroke : @color})

  # (Re-)connects a link to the converter slots.
  # Needs to be called everytime we move/drag a Converter.
  # Also has to be called after drawing the converters.
  #
  adjust_to_converter: => @r.connection(@shape)

class @Converter
  STYLE_SELECTED : {fill : '#cff', 'stroke' : '#f00' }
  STYLE_HIGHLIGHT : {'stroke' : '#f00'}

  constructor: (args) ->
    [key, pos_x, pos_y, sector, use, hidden, fill_color, stroke_color] = args
    @key = key
    @pos_x = pos_x
    @pos_y = pos_y
    @use = use
    @sector = sector
    @links = []
    @highlighted = false
    @dirty = false
    @hidden = hidden
    @fill_color = fill_color
    @stroke_color = stroke_color
    @r = GRAPH.r

    GRAPH.converters[key] = this

  # Draws the Converter on the raphael space.
  # *Warning*: The order of the elements being drawed defines their z-index.
  #           We want the links to appear behind the converter boxes, therefore
  #           call draw() on converters after the links.
  #
  draw: ->
    @drawConverterBox()
    @hide() if @isHidden()
    @addEventListeners()

  drawConverterBox: =>
    txt_attributes =
      'text-anchor' : 'start'
      'font-family' : 'arial'
      'font-weight' : 400
      "font-size" : 11

    pos_x = @pos_x
    pos_y = @pos_y

    box = @r.rect(pos_x, pos_y, 80, 50)
    box.attr(@getBoxAttributes())
    box.converter = this

    # Creating text nodes of converter
    box.sector_node = @r.text(0, 0, @getSectorUseShortcut())
    box.text_node = @r.text(0, 0, @key).attr({'text-anchor': 'start'})
    box.value_node = @r.text(0,0, '').attr({'text-anchor': 'start'})

    # Default styles for text nodes
    box.text_node.attr(txt_attributes)
    box.value_node.attr(txt_attributes)

    @box = box
    @position_subnodes()

  addEventListeners: =>
    @box.node.onclick = (evt) =>
      if evt.altKey && evt.shiftKey
        @toggle_visibility()
      else if evt.altKey
        @toggle_selection()
      else if evt.shiftKey
        @highlight_toggle()
      false

    @box.node.ondblclick = (evt) =>
      if !evt.altKey || !evt.shiftKey
        url = "#{window.converter_url_prefix}/#{@key}"
        window.open(url, '_blank')
      false

  addDragEventListeners: =>
    @box.attr({cursor: "move"})
    @box.dragger = -> GRAPH.elements_drag($.merge([this], GRAPH.selected))
    @box.move = (dx, dy) -> GRAPH.elements_move($.merge([this], GRAPH.selected), dx, dy)
    @box.up = -> GRAPH.elements_up($.merge([this],GRAPH.selected))
    @box.drag(@box.move, @box.dragger, @box.up)

  # Has Converter changed attribute values?
  isDirty: -> @dirty == true

  # Mark Converter changed.
  markDirty: -> @dirty = true

  # Highlight converters and their links.
  highlight_toggle: ->
    if @highlighted then @highlight_off() else @highlight_on()

  highlight_on: ->
    @highlighted = true
    @box.attr(this.STYLE_HIGHLIGHT)
    link.highlight_on() for link in @links

  highlight_off: ->
    @highlighted = false
    @box.attr({'stroke' : this.stroke_color})
    link.highlight_off() for link in @links

  # Select multiple converters to drag them at the same time.
  toggle_selection: ->
    if _.indexOf(GRAPH.selected, this.box) >= 0 then @unselect() else @select()

  unselect: ->
    GRAPH.selected = _.without(GRAPH.selected, @box)
    @box.attr(@getBoxAttributes())

  select: ->
    GRAPH.selected.push(@box)
    @box.attr(@STYLE_SELECTED)

  getBox: -> @box

  # Apply the passed raphael parameters to all the shapes of a converter.
  # Including links, Slots, Text nodes.
  # This is mostly useful for assigning opacity.
  #
  apply_to_all: (attrs) ->
    @box.attr(attrs)
    @box.text_node.attr(attrs)
    @box.value_node.attr(attrs)
    @input_slot().attr(attrs)
    @output_slot().attr(attrs)
    for link in @links
      link.shape.bg.attr(attrs)
      link.shape.line.attr(attrs)

  toggle_visibility: ->
    if @isHidden() then @show() else @hide()

  isHidden: -> @hidden == true

  getHidden: -> @hidden

  setHidden: (value) ->
    this.markDirty() if @hidden != value
    @hidden = value

  hide: ->
    @setHidden(true)
    @apply_to_all({opacity : 0.1})

  show: ->
    @setHidden(false)
    @apply_to_all({opacity : 1.0})

  update_result: (text) ->
    box.value_node.text = text

  input_slot: ->
    unless @input_slot_element?
      @input_slot_element = GRAPH.r.circle(0,0, 5)
    @input_slot_element

  output_slot: ->
    unless @output_slot_element?
      @output_slot_element = GRAPH.r.circle(0,0, 5)
    @output_slot_element

  getSectorUseShortcut: ->
    sector_shortcut = @sector.charAt(0).toUpperCase()
    use_shortcut = @use.charAt(0).toUpperCase()

    shortcut = sector_shortcut
    if use_shortcut != 'U'
      shortcut = shortcut + " " + use_shortcut

    shortcut

  getBoxAttributes: ->
    {
      fill: @fill_color
      'fill-opacity': 1
      'stroke-width' : 2
      stroke : @stroke_color
    }

  getAttributes: ->
    {
      x : @pos_x
      y : @pos_y
      hidden : @getHidden()
    }

  update_position: (pos_x, pos_y) =>
    pos_x = pos_x - (pos_x % 20)
    pos_y = pos_y - (pos_y % 20)
    @pos_x = pos_x
    @pos_y = pos_y
    @markDirty()
    GRAPH.updated_coordinates[@id] = [pos_x, pos_y]

  # Position the child-shapes according to the converter shape.
  position_subnodes: =>
    pos_x = @box.attr('x')
    pos_y = @box.attr('y')

    @box.sector_node.attr( {x : pos_x - 10, y : pos_y + 35})
    @box.text_node.attr(   {x : pos_x + 5,  y : pos_y + 10})
    @box.value_node.attr(  {x : pos_x + 5,  y : pos_y + 40})

    @input_slot().attr( {cx : pos_x - 5 , cy : pos_y + 20 })
    @output_slot().attr({cx : pos_x + 85, cy : pos_y + 20 })

  # Relative move to.
  # Snaps converter to an (invisible) grid.
  #
  moveTo: (dx, dy) ->
    b = @box
    x = b.ox + dx
    y = b.oy + dy
    x = x - (x % GRAPH.SNAPPABLE_GRID_SIZE)
    y = y - (y % GRAPH.SNAPPABLE_GRID_SIZE)
    att = if b.type == "rect" then  {x: x, y: y} else {cx: x, cy: y}
    b.attr(att)
    @position_subnodes()
    link.adjust_to_converter() for link in @links
