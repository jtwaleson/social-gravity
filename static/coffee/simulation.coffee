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
      drag: (event, ui) =>
        dx = @draglocation_x - ui.offset.left
        dy = @draglocation_y - ui.offset.top
        if Math.abs(dx) + Math.abs(dy) > 20
          spyglass.clear()
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
    @words_worker_ready = yes
    @running = no
    @set_up_hashchange()
    @chaos_key_timeout = -1
    @he_i_triggered_the_hash_change = no
    @button = new Button(1, "&#x25b6;", "Start/stop",  "s",  "", =>
      @toggle()
    )
    new Button(2, "&#x2205;", "Clear", "c",  "", =>
      @clear()
    )
    new Button(2, "&#x2743;", "Randomize, repeat ", "r",  "", ->
      if $(".chaosmeter").length > 0
        $(".chaosmeter").width($(".chaosmeter").width() + 10)
      else
        $(@).after(
          $("<div>").addClass("chaosmeter")
        )
      if simulation.chaos_key_timeout > -1
        clearTimeout(simulation.chaos_key_timeout)
      simulation.chaos_key_timeout = setTimeout(
        ->
          simulation.chaos_key_timeout = -1
          simulation.randomize_positions($(".chaosmeter").width()*5)
          $(".chaosmeter").remove()
        500
      )
    )
    new Button(3, "&#x2222;", "Find loaded users", "f",  "", ->
      if $(".person-finder").length > 0
        $(".person-finder").focus()
        return

      $("<input>")
          .addClass("person-finder")
          .attr("type", "text")
          .attr("placeholder", "name / description")
          .insertAfter(@)
          .focus()
          .keyup( (event) ->
            $(".searching").removeClass('searching')
            val = $(@).val().toLowerCase()
            if val.length > 0
              for id, friend of simulation.friends
                w = friend.words
                w = if w? then w else ''
                if w.indexOf(val) >= 0
                  friend.div.addClass('searching')
          )
          .keydown( (event) ->
            if event.keyCode == 27
              $(@).remove()
              $(".searching").removeClass('searching')
          )
          .blur( (event) ->
            if $(@).val().length == 0
              $(".searching").removeClass('searching')
              $(@).remove()
          )
    )
    @expand_button = new Button(5, "expand", "Expand", "e",  "", =>
      highlighted = (friend for id, friend of @friends when friend.highlight)

      if highlighted.length == 0
        alert 'Impossibru'
      else
        ids = {}
        for f in highlighted
          for id, _ of f.friends
            if id not of ids
              ids[id] = 0
            ids[id] += 1

        if highlighted.length > 1
          min = parseInt(prompt 'Enter the threshold X. We will then load everyone who is followd by at least X of your selected persons.')
          if isNaN(min) or 1 > min > highlighted.length
            alert "Not a valid number, has to be larger than 0 and smaller than the number of people you selected (#{ highlighted.length})."
            return
          else
            for id, num of ids
              if ids[id] < min
                delete ids[id]
        downloader.q.tasks = []
        @clear()
        for f in highlighted
          @add_friend(f.id)
        for id, _ of ids
          @add_friend(id)
    )
    @expand_button.div.parent().hide()
    @box = $("<div>").attr('id', 'box').appendTo("body")
    @redraw()
    setTimeout(
      ->
        $(window).trigger('hashchange')
      500
    )

  set_up_hashchange: ->
    $(window).bind('hashchange', (event) =>
      event.preventDefault()
      if @he_i_triggered_the_hash_change
        @he_i_triggered_the_hash_change = no
        return
      h = window.location.hash
      parts = {}
      for o in ({key: a[0].replace('#', ''), value: a[1]} for a in (part.split("=") for part in h.split("&")))
        parts[o.key] = o.value
      @clear(no)
      if downloader?
        downloader.visual_insert = no
      if parts.friends? and parts.friends.length > 0
        friends = parts.friends.split(',')
        for id in friends
          @add_friend(id)
    )

  message_from_words_worker: (event) =>
    @words_worker_ready = yes

    if 'console' of event.data
      console.log(event.data.console)

    if 'words' of event.data
      @friends[event.data.id].words = event.data.words
      @friends[event.data.id].words_list = event.data.words.split(' ')
    else
      div = $("#words").empty()
      for w in event.data
        $("<li>").text(w.word).appendTo(div)

  hash_change: ->
    f = {}
    for id, _ of downloader.to_load
      f[id] = 1
    for id, _ of @friends
      f[id] = 1
    f = (id for id, _ of f)
    friends = "friends=#{f.join(",")}"
    zoom = "zoom=#{@zoom.zoom},#{@zoom.x},#{@zoom.y}"
    hash = [zoom, friends].join("&")
    @he_i_triggered_the_hash_change = yes
    window.location.hash = "##{ hash }"
  message_from_gravity_worker: (event) =>
    if 'console' of event.data
      console.log(event.data.console)
    if 'popular_guys' of event.data
      div = $("#who_is_here")
      div.empty()
      guys = event.data.guys[0..4]
      for id in guys
        $("<li>").text("@#{ @friends[id].name }").appendTo(div)
      if event.data.guys.length > 5
        $("<li>").text("...").appendTo(div)

      $("#who_to_follow").data('who_to_follow', event.data.popular_guys)
      if @words_worker_ready
        @words_worker.postMessage({friends: event.data.guys})
    else if 'popularity' of event.data
      for id, pop of event.data.popularity
        for n in [0..10]
          @friends[id].div.removeClass("fade#{n}")
        fadeclass = "fade#{pop}"
        if fadeclass isnt "fadeNaN"
          @friends[id].div.addClass(fadeclass)
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
          10
        )

  randomize_positions: (amount = -1) ->
    for id, friend of @friends when not friend.pinned
      friend.randomize_position(amount)
      @gravity_worker.postMessage({id: friend.id, new_x: friend.x, new_y: friend.y})
    @redraw()

  clear: (trigger_hash = yes) ->
    @stop()
    @gravity_worker.postMessage({'clear': yes})
    for id, friend of @friends
      friend.div.remove()
    @friends = {}
    @redraw()
    if trigger_hash
      @hash_change()

  take_hostage: (f) ->
    @gravity_worker.postMessage({id: f.id, force_x: f.x, force_y: f.y})

  release_hostage: (f) ->
    @gravity_worker.postMessage({release_hostage: f.id})

  register: (friend) ->
    friend.set_zoom(@zoom)
    @friends[friend.id] = friend

    @gravity_worker.postMessage({new_friend: friend.id, x: friend.x, y: friend.y, friends: friend.friends})
    @words_worker.postMessage({new_friend: friend.id, strings: friend.get_strings(), friends: friend.friends})

    if downloader.visual_insert
      if @lastclicked?
        @lastclicked.click()
      @lastclicked = friend
      friend.click()
    else
      friend.redraw()

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
    update_overlay()
  
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

  add_protagonist: (name, load_friends, load_self) =>
    downloader.q.push(
      {name: name}
      (result) =>
        if result.error?
          alert("Could not retrieve @#{ name }. Either the user doesn't exist or you are being rate limited.")
        else if result.result.protected
          alert("This user has a protected account. We can not see his/her friends")
        else
          if load_self and result.result.id not of @friends
            friend = new Friend(result.result)
          if load_friends
            for id in result.result.friends.ids.reverse()
              @add_friend id
          @hash_change()
    )
  add_friend: (id) =>
    downloader.to_load[id] = 1
    downloader.q.push(
      {id: id}
      (result) =>
        if result.error?
          downloader.failed_downloads += 1
        else
          if id of @friends
            return
          new Friend(result.result)
    )
  check_expand_button: ->
    len = $(".friend.highlight").length
    if len > 1 or (not (@lastclicked?) and len > 0)
      @expand_button.div.parent().show()
    else
      @expand_button.div.parent().hide()

class Button
  constructor: (li_number, caption, description, keystroke, divclass, func) ->
    @div = $("<button>")
              .html(caption)
              .addClass(divclass)
              .click(func)
              .attr('title', description + ' - Hot key: ' + keystroke)
              .hover(
                ->
                  $(@).html(description)
                ->
                  $(@).html(caption)
              )

                          
    li = $("ul#menu li#li_#{li_number}")
    li.append(@div)
    shortcut.add(
      keystroke
      =>
        @div.click()
      {disable_in_input: yes}
    )

window.Button = Button

$ ->
  for i in [0..6]
    $("<li>").attr('id', "li_#{ i }").appendTo($("#menu"))
  window.simulation = new Simulation
  $('body').mousewheel( (e, delta) ->
    simulation.zoom.do_zoom(e.originalEvent.wheelDelta, e.originalEvent.pageX, e.originalEvent.pageY)
  )
  shortcut.add(
    'space'
    -> simulation.toggle()
    {disable_in_input: yes}
  )
  shortcut.add(
    'left'
    -> simulation.zoom.move(-100,0)
    {disable_in_input: yes}
  )
  shortcut.add(
    'right'
    -> simulation.zoom.move(100,0)
    {disable_in_input: yes}
  )
  shortcut.add('up', -> simulation.zoom.move(0,-100))
  shortcut.add('down', -> simulation.zoom.move(0,100))
  shortcut.add('Ctrl+up', -> simulation.zoom.do_zoom(1))
  shortcut.add('Ctrl+down', -> simulation.zoom.do_zoom(-1))
  if !window.Worker
    alert('Sorry, your browser does not support web workers. Try more recent versions of Chrome, Firefox, Opera or Safari')
