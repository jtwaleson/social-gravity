class Friend
  constructor: (data) ->
    if data.friends.length == 1
      @friends = data.friends[0].ids
    else
      @friends = []
    @id = data.id
    @x = Math.random()*1800
    @y = Math.random()*800

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
           
    @.reposition()
    simulation.register(@)
    friends[@id] = @
  click: ->
    @div.css('background-color', 'black')
    ctx = $("#canvas")[0].getContext("2d")
    pos = @div.position()
    pos.left += @div.width()/2
    pos.top += @div.height()/2
    ctx.beginPath()
    ctx.lineWidth = 3
    for i in @friends
      other = $("#"+i)
      if other.length > 0
        otherpos = other.position()
        otherpos.left += other.width()/2
        otherpos.top += other.height()/2
        ctx.moveTo(pos.left, pos.top)
        ctx.lineTo(otherpos.left, otherpos.top)
    ctx.strokeStyle = '#000'
    ctx.stroke()
  
  dblclick: ->
    @div.css('background-color', 'red')
  setX: (x) ->
    @x = x
    @.reposition()
  setY: (y) ->
    @y = y
    @.reposition()
  reposition: ->
    @div.css('top', @y)
        .css('left', @x)

  
window.Friend = Friend
window.friends = {}
