class Zoom
  factor = 1.2
  constructor: (simulation) ->
    @simulation = simulation
    @x = 0
    @y = 0
    @zoom = 1
    @mousedown = no
    $("body").draggable({
      helper: () =>
        $("<div>").css('position','absolute').css('width', '100px').css('height', '100px')
      start: (event, ui) =>
        @draglocation_x = ui.offset.left
        @draglocation_y = ui.offset.top
      stop: (event, ui) =>
        console.log(ui)
      drag: (event, ui) =>
        dx = @draglocation_x - ui.offset.left
        dy = @draglocation_y - ui.offset.top
        if Math.abs(dx) + Math.abs(dy) > 20
          @x += dx*@zoom
          @y += dy*@zoom
          simulation.redraw()
          @draglocation_x = ui.offset.left
          @draglocation_y = ui.offset.top

    })
  translate_x_back: (x) ->
    (x * @zoom) + @x
  translate_y_back: (y) ->
    (y * @zoom) + @y
  translate_x: (x) ->
    (x - @x)/@zoom
  translate_y: (y) ->
    (y - @y)/@zoom
  do_zoom: (delta, x = $("body").width() / 2, y = $("body").height() / 2) ->
    zoom_before = @zoom
    if delta < 0
      @zoom = @zoom * factor
    else if delta > 0
      @zoom = @zoom / factor
    @x = (x*zoom_before + @x) - x * @zoom
    @y = (y*zoom_before + @y) - y * @zoom
    @simulation.redraw()
    
  move: (x,y) ->
    @x += x * @zoom
    @y += y * @zoom
    @simulation.redraw()

class Simulation
  constructor: ->
    @zoom = new Zoom(@)
    @friends = {}
    @gravity_worker = new Worker 'js/gravity_worker.js'
    @gravity_worker.onmessage = @message_from_gravity_worker
    @words_worker = new Worker 'js/words_worker.js'
    @words_worker.onmessage = @message_from_words_worker
    @running = no
    @button = new Button("&#x25b6;", "Start/stop",  "s",  "", =>
      @toggle()
    )
    new Button("&#x2743;", "Randomize", "r",  "", =>
      @randomize_positions()
    )
    new Button("&#x2205;", "Clear", "c",  "", =>
      @clear()
    )
    new Button("&#x2222;", "Find users in the field", "f",  "", ->
      $("<input>")
          .addClass("person-finder")
          .attr("type", "text")
          .insertAfter(@)
          .focus()
          .change( ->
          )
          .keyup( (event) ->
            $(".searching").removeClass('searching')
            if event.keyCode == 27
              $(@).remove()
            val = $(@).val().toLowerCase()
            if val.length > 0
              for id, friend of simulation.friends
                s = friend.data.screen_name
                n = friend.data.name
                n = if n? then n.toLowerCase() else ''
                s = if s? then s.toLowerCase() else ''
                if s.indexOf(val) >= 0 or n.indexOf(val) >= 0
                  friend.div.addClass('searching')
          )
          .blur( ->
            $(@).remove()
            $(".searching").removeClass('searching')
          )
    )
    @box = $("<div>").attr('id', 'box').appendTo("body")
    @redraw()

  message_from_words_worker: (event) ->
    if 'console' of event.data
      console.log(event.data)
      return
    div = $("#words").empty()
    for w in event.data
      $("<li>").text(w.word).appendTo(div)

  message_from_gravity_worker: (event) =>
    if 'console' of event.data
      console.log(event.data.console)
      return
    if 'popular_guys' of event.data
      div = $("#who_to_follow")
      div.empty()
      for id in event.data.guys
        $("<li>").text(@friends[id].name).appendTo(div)
#      for id, score of event.data.popular_guys
#        downloader.by_user_id(id, (data) ->
#            console.log(data.screen_name + " -> " + score)
#          , (message) ->
#            alert(message)
#        )
      @words_worker.postMessage({friends: event.data.guys})
    else
      for d in event.data
        friend = @friends[d.id]
        friend.setX(d.x)
        friend.setY(d.y)
      @redraw()
      if @running
        setTimeout(
          =>
            @gravity_worker.postMessage({continue: yes})
          100
        )

  randomize_positions: ->
    for id, friend of @friends
      friend.randomize_position()
      @gravity_worker.postMessage({id: friend.id, new_x: friend.x, new_y: friend.y})
    @redraw()

  clear: ->
    @stop()
    @gravity_worker.postMessage({'clear': yes})
    for id, friend of @friends
      friend.div.remove()
    @friends = {}
    @redraw()

  take_hostage: (f) ->
    @gravity_worker.postMessage({id: f.id, force_x: f.x, force_y: f.y})

  release_hostage: (f) ->
    @gravity_worker.postMessage({release_hostage: f.id})

  register: (friend) ->
    friend.set_zoom(@zoom)
    @friends[friend.id] = friend

    @gravity_worker.postMessage({new_friend: friend.id, x: friend.x, y: friend.y, friends: friend.friends})
    @words_worker.postMessage({new_friend: friend.id, strings: friend.get_strings(), friends: friend.friends})

    for id, f of @friends when f.highlight
      f.click()
    friend.click()

  friends_loaded: ->
    for id, friends of @friends
      return yes
    return no
  start: ->
    if @friends_loaded()
      @gravity_worker.postMessage({start: yes})
      @running = yes
      @button.div.html('&#x25a0;').addClass('active')
    else
      alert "There are no users in the field. Load some users first."

  stop: ->
    @running = no
    @button.div.html('&#x25b6;').removeClass('active')
  toggle: ->
    if @running
      @stop()
    else
      @start()
  redraw: ->
    @box
        .css('top', @zoom.translate_y(0))
        .css('left', @zoom.translate_x(0))
        .css('width',  "#{ @zoom.translate_x($("body").width()) - @zoom.translate_x(0)}px")
        .css('height', "#{@zoom.translate_y($("body").height()) - @zoom.translate_y(0)}px")

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
  who_is_popular_here: (x,y) =>
    @gravity_worker.postMessage({who_is_popular_here: yes, x: x, y: y, zoom: @zoom.zoom})
  add_protagonist: (name) =>
    downloader.q.push(
      {name: name}
      (result) =>
        if result.error?
          alert("Could not retrieve @#{ name }. Either the user doesn't exist or you are being rate limited.")
        else if result.result.protected
          alert("This user has a protected account. We can not see his/her friends")
        else
          if result.result.id not of @friends
            friend = new Friend(result.result)
          for id in result.result.friends.ids.reverse()
            @add_friend id
    )
  add_friend: (id) =>
    if id of @friends
      return
    downloader.q.push(
      {id: id}
      (result) =>
        if result.error?
          downloader.failed_downloads += 1
        else
          new Friend(result.result)
    )

class Button
  constructor: (caption, description, keystroke, divclass, func) ->
    @div = $("<button>")
              .html(caption)
              .addClass(divclass)
              .click(func)
              .attr('title', description + ' - Hot key: ' + keystroke)
                          
    li = $("<li>")
    li.append(@div)
    li.appendTo $("#menu")
    shortcut.add(
      keystroke
      =>
        @div.click()
      {disable_in_input: yes}
    )

window.Button = Button

$ ->
  window.simulation = new Simulation
  $('body').mousewheel( (e, delta) ->
    simulation.zoom.do_zoom(e.originalEvent.wheelDelta, e.originalEvent.pageX, e.originalEvent.pageY)
  )
  shortcut.add('space', -> simulation.toggle())
  shortcut.add('left', -> simulation.zoom.move(-100,0))
  shortcut.add('right', -> simulation.zoom.move(100,0))
  shortcut.add('up', -> simulation.zoom.move(0,-100))
  shortcut.add('down', -> simulation.zoom.move(0,100))
  shortcut.add('Ctrl+up', -> simulation.zoom.do_zoom(1))
  shortcut.add('Ctrl+down', -> simulation.zoom.do_zoom(-1))
  if !window.Worker
    alert('Sorry, your browser does not support web workers. Try more recent versions of Chrome, Firefox, Opera or Safari')
