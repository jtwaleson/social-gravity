class Zoom
  factor = 1.2
  constructor: (simulation) ->
    @simulation = simulation
    @x = 0
    @y = 0
    @zoom = 1
    @mousedown = no
    $("body").mousedown( (event) =>
      @draglocation_x = event.pageX
      @draglocation_y = event.pageY
      @mousedown = yes
    )
    $("body").mouseup( =>
      @mousedown = no
    )
    $("body").mousemove( (event) =>
      if @mousedown
        dx = @draglocation_x - event.pageX
        dy = @draglocation_y - event.pageY
        if Math.abs(dx) + Math.abs(dy) > 50
          @x += dx*@zoom
          @y += dy*@zoom
          simulation.redraw()
          @draglocation_x = event.pageX
          @draglocation_y = event.pageY
    )
  translate_x_back: (x) ->
    (x * @zoom) + @x
  translate_y_back: (y) ->
    (y * @zoom) + @y
  translate_x: (x) ->
    (x - @x)/@zoom
  translate_y: (y) ->
    (y - @y)/@zoom
  do_zoom: (delta, x = @.get_width() / 2, y = @.get_height() / 2) ->
    zoom_before = @zoom
    if delta < 0
      @zoom = @zoom * factor
    else if delta > 0
      @zoom = @zoom / factor
    @x = (x*zoom_before + @x) - x * @zoom
    @y = (y*zoom_before + @y) - y * @zoom
    @simulation.redraw()
  get_width: ->
    1000
  get_height: ->
    1000


class Simulation
  constructor: ->
    @zoom = new Zoom(@)
    @friends = {}
    @gravity_worker = new Worker 'js/gravity_worker.js'
    @gravity_worker.onmessage = @message_from_worker
    @running = no
    @button = new Button("&#x25b6;", "s",  "", =>
      @toggle()
    )
    new Button("chaos", "r",  "", =>
      @randomize_positions()
    )
  message_from_worker: (event) =>
    if 'console' of event.data
      console.log(event.data.console)
      return
    for d in event.data
      friend = @friends[d.id]
      friend.setX(d.x)
      friend.setY(d.y)
    @redraw()
    @gravity_worker.postMessage({continue: yes})
  randomize_positions: ->
    for id, friend of @friends
      friend.randomize_position()
      @gravity_worker.postMessage({id: friend.id, new_x: friend.x, new_y: friend.y})
    @redraw()
  register: (friend) ->
    @friends[friend.id] = friend
    @gravity_worker.postMessage({new_friend: friend.id, x: friend.x, y: friend.y, friends: friend.friends})
    friend.set_zoom(@zoom)
  start: ->
    @gravity_worker.postMessage({start: yes})
    @running = yes
    $(@button.div).html('&#x25a0;')
  stop: ->
    @gravity_worker.postMessage({stop: yes})
    @running = no
    $(@button.div).html('&#x25b6;')
  toggle: ->
    if @running
      @stop()
    else
      @start()
  redraw: ->
    friend.redraw() for id, friend of @friends

    canvas = $("#canvas")[0]
    canvas.width--
    canvas.width++
    ctx = canvas.getContext("2d")
    ctx.beginPath()
    ctx.lineWidth = 3
    friend.redraw_lines(ctx) for id, friend of @friends
    ctx.strokeStyle = '#000'
    ctx.stroke()
  
  redraw_lines: ->
    for id, friend of @friends
      friend.div.removeClass('follows').removeClass('followed')
      friend.lines_to = []
    for id, highlighted_friend of @friends when highlighted_friend.highlight
      for followed_by_highlighted, _ of highlighted_friend.friends when followed_by_highlighted of @friends
        other = @friends[followed_by_highlighted].div
        other.addClass('followed')
        highlighted_friend.lines_to.push(@friends[followed_by_highlighted])
      for id, friend of @friends
        if highlighted_friend.id of friend.friends
          other = friend.div
          other.addClass('follows')
          friend.lines_to.push(highlighted_friend)
    @redraw()
  new_center: (x,y) ->
    @gravity_worker.postMessage({new_x: x, new_y: y})

class Button
  constructor: (caption, keystroke, divclass, func) ->
    @div = $("<button>")
              .html(caption)
              .addClass(divclass)
              .click(func)
              .attr('title', 'Hot key: ' + keystroke)
                          
    li = $("<li>")
    li.append(@div)
    li.appendTo $("#menu")
    shortcut.add(keystroke, => @div.click())

window.Button = Button
$ ->
  window.simulation = new Simulation
  $('body').mousewheel( (e, delta) ->
    simulation.zoom.do_zoom(e.originalEvent.wheelDelta, e.originalEvent.pageX, e.originalEvent.pageY)
  )
