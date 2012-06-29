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
    @name = data.screen_name
    @randomize_position()
    @div = $("<div>")
          .addClass('friend')
          .appendTo("body")
          .attr('id', @id)
          .bind('click', (event) => @click())
          .bind('dblclick', (event) => @dblclick())
          .attr('title', "@" + data.screen_name + " - " + data.description)
    $("<img>")
      .attr('src', data.profile_image_url)
      .appendTo(@div)
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
      otherpos = friend.div.position()
#      otherpos.left += friend.div.outerWidth()/2
#      otherpos.top += friend.div.outerHeight()/2
      dx = pos.left - otherpos.left
      dy = pos.top - otherpos.top
      line_len = Math.sqrt(dx*dx+dy*dy) - friend.div.width()/1.8
      angle = Math.atan2(dx, dy)
      new_x = pos.left - line_len * Math.sin(angle)
      new_y = pos.top - line_len * Math.cos(angle)
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
    @div.css('top', @zoom.translate_y(@y))
        .css('left', @zoom.translate_x(@x))
  set_zoom: (zoom) ->
    @zoom = zoom

  
window.Friend = Friend
