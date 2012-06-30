class Friend
  constructor: (data) ->
    @data = data
    @friends = {}
    if data.friends? and data.friends? and data.friends.ids?
      for id in data.friends.ids
        @friends[id] = 1
    @id = data.id
    @highlight = no
    @lines_to = []
    @protected = data.protected
    @name = data.screen_name
    @randomize_position()
    @hostage = no
    @locked = no
    @div = $("<div>")
          .addClass('friend')
          .appendTo("body")
          .attr('id', @id)
          .bind('click', (event) => @click())
          .bind('dblclick', (event) => @dblclick())
          .attr('title', "@" + data.screen_name + " - " + data.description)
          .draggable({
            start: (event, ui) =>
              @hostage = yes
              event.stopPropagation()
              ui.helper.bind(
                "click.prevent"
                (event) ->
                  event.preventDefault()
              )
            drag: (event, ui) =>
              event.stopPropagation()
              simulation.force_position({
                id: @id
                x: @zoom.translate_x_back(ui.offset.left)
                y: @zoom.translate_y_back(ui.offset.top)
              })
            stop: (event, ui) =>
              @hostage = no
              event.stopPropagation()
              setTimeout(
                ->
                  ui.helper.unbind("click.prevent")
                300
              )
          })

    if @protected
      @div.addClass 'protected'
    $("<img>")
      .attr('src', data.profile_image_url)
      .appendTo(@div)
      .bind('dragstart', (event) -> event.preventDefault() )
    $("<div>")
      .text(data.name)
      .addClass("name")
      .appendTo(@div)
           
    simulation.register(@)
  get_strings: ->
    s = [@data.description, @data.location]
    if @data.status
      if @data.status.text
        s.push(@data.status.text)
    s.join(" ")
  randomize_position: ->
    @x = Math.random()*innerWidth
    @y = Math.random()*innerHeight
  click: ->
    @highlight = !@highlight
    @div.toggleClass('highlight')
    simulation.redraw_lines()
  
  dblclick: ->
    @div.css('background-color', 'red')
  setX: (x) ->
    @x = x
  setY: (y) ->
    @y = y
  redraw_lines: (ctx) ->
    pos = @div.position()
#    pos.left += @div.outerWidth()/2
#    pos.top += @div.outerHeight()/2

    for friend in @lines_to
      otherdiv = friend.div
      otherpos = otherdiv.position()
#      otherpos.left += friend.div.outerWidth()/2
#      otherpos.top += friend.div.outerHeight()/2
      dx = pos.left - otherpos.left
      dy = pos.top - otherpos.top
#      line_len = Math.sqrt(dx*dx+dy*dy) - friend.div.width()/1.8
      angle = Math.atan2(dx, dy)
      new_x = otherpos.left + otherdiv.outerWidth()/1.8 * Math.sin(angle)
      new_y = otherpos.top + otherdiv.outerHeight()/1.8 * Math.cos(angle)
      old_x = pos.left - @div.outerWidth()/1.8 * Math.sin(angle)
      old_y = pos.top - @div.outerHeight()/1.8 * Math.cos(angle)
      ctx.moveTo(old_x, old_y)
      ctx.lineTo(new_x, new_y)
      @arrow_head(ctx, angle-.50, new_x, new_y)
      @arrow_head(ctx, angle+.50, new_x, new_y)
      
  arrow_head: (ctx, angle, x, y) ->
      ctx.moveTo(x, y)
      line_len = 20
      new_x = x + line_len * Math.sin(angle)
      new_y = y + line_len * Math.cos(angle)
      ctx.lineTo(new_x, new_y)
     
  redraw: ->
    if not @hostage
      @div.css('top', @zoom.translate_y(@y))
          .css('left', @zoom.translate_x(@x))
  set_zoom: (zoom) ->
    @zoom = zoom

window.Friend = Friend
