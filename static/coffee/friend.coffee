class Friend
  constructor: (data) ->
    @friends = {}
    if data.friends.length == 1
      for id in data.friends[0].ids
        @friends[id] = 1
    @id = data.id
    @x = Math.random()*1800
    @y = Math.random()*800
    @highlight = no
    @lines_to = []

    @div = $("<div>")
          .addClass('friend')
          .appendTo("body")
          .attr('id', @id)
          .bind('click', (event) => @click())
          .bind('dblclick', (event) => @dblclick())
    $("<img>")
      .attr('src', data.profile_image_url)
      .appendTo(@div)
    $("<div>")
      .text(data.name)
      .addClass("name")
      .appendTo(@div)
           
    simulation.register(@)
    @redraw()
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
    pos.left += @div.width()/2
    pos.top += @div.height()/2

    for friend in @lines_to
      otherpos = friend.div.position()
      otherpos.left += friend.div.width()/2
      otherpos.top += friend.div.height()/2
      ctx.moveTo(pos.left, pos.top)
      ctx.lineTo(otherpos.left, otherpos.top)

  redraw: ->
    @div.css('top', @zoom.translate_y(@y))
        .css('left', @zoom.translate_x(@x))
  set_zoom: (zoom) ->
    @zoom = zoom

  
window.Friend = Friend
