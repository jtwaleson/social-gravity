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

    @div = $("<div>")
          .addClass('friend')
          .appendTo("#playfield")
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
    @.redraw()
  click: ->
    @highlight = !@highlight
    @div.toggleClass('highlight')
    simulation.redraw_lines()
  
  dblclick: ->
    @div.css('background-color', 'red')
  setX: (x) ->
    @x = x
    @.redraw()
  setY: (y) ->
    @y = y
    @.redraw()
  redraw: ->
    @div.css('top', @zoom.translate_y(@y))
        .css('left', @zoom.translate_x(@x))
  set_zoom: (zoom) ->
    @zoom = zoom

  
window.Friend = Friend
