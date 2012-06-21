class Zoom
  factor = 1.2
  constructor: (simulation) ->
    @simulation = simulation
    @x = 0
    @y = 0
    @zoom = 1
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
  message_from_worker: (event) =>
    for d in event.data
      friend = @friends[d.id]
      friend.setX(d.x)
      friend.setY(d.y)
  register: (friend) ->
    @friends[friend.id] = friend
    @gravity_worker.postMessage({new_friend: friend.id, x: friend.x, y: friend.y, friends: friend.friends})
    friend.set_zoom(@zoom)
  start: ->
    @gravity_worker.postMessage({start: yes})
  stop: ->
    @gravity_worker.postMessage({stop: yes})
  start_stop: ->
    @gravity_worker.postMessage({start_stop: yes})
  redraw: ->
    friend.redraw() for id, friend of @friends
  redraw_lines: ->
    ctx = $("#canvas")[0].getContext("2d")
    ctx.beginPath()
    ctx.lineWidth = 3

    for id, friend of @friends
      friend.div.removeClass('follows').removeClass('followed')

    for id, highlighted_friend of @friends when highlighted_friend.highlight
      pos = highlighted_friend.div.position()
      pos.left += highlighted_friend.div.width()/2
      pos.top += highlighted_friend.div.height()/2

      for followed_by_highlighted, _ of highlighted_friend.friends when followed_by_highlighted of @friends
        other = @friends[followed_by_highlighted].div
        other.addClass('followed')
        if other.length > 0
          otherpos = other.position()
          otherpos.left += other.width()/2
          otherpos.top += other.height()/2
          ctx.moveTo(pos.left, pos.top)
          ctx.lineTo(otherpos.left, otherpos.top)

      for id, friend of @friends
        if highlighted_friend.id of friend.friends
          other = friend.div
          other.addClass('follows')
          otherpos = other.position()
          otherpos.left += other.width()/2
          otherpos.top += other.height()/2
          ctx.moveTo(pos.left, pos.top)
          ctx.lineTo(otherpos.left, otherpos.top)

    ctx.strokeStyle = '#000'
    ctx.stroke()
  

class Button
  constructor: (keystroke, divclass, func) ->
    btn = $("<button>")
              .text(keystroke)
              .addClass(divclass)
              .click( func
              )
                          
    li = $("<li>")
    li.append(btn)
    li.appendTo $("#menu")
    shortcut.add(keystroke, func)


window.simulation = new Simulation
window.Button = Button
$ ->
  $('#playfield').mousewheel( (e, delta) ->
    simulation.zoom.do_zoom(e.originalEvent.wheelDelta, e.originalEvent.pageX, e.originalEvent.pageY)
  )
  new Button("s", "", ->
    simulation.start_stop()
  )
