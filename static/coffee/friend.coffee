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
    @pinned = no
    @words = ''
    title = "@#{ data.screen_name }"
    if data.description? and data.description.length > 0
      title += " - #{ data.description }"
    title += " - followers: #{ data.followers_count } - follows: #{ data.friends_count }"
    @div = $("<div>")
          .addClass('friend')
          .appendTo("body")
          .attr('id', @id)
          .bind('click', (event) => @click(event))
          .bind('dblclick', (event) => @dblclick(event))
          .attr('title', title)
          .draggable({
            start: (event, ui) =>
              @hostage = yes
              if not @highlight
                @click()
                @temporary_highlight = yes
              event.stopPropagation()
              ui.helper.bind(
                "click.prevent"
                (event) ->
                  event.preventDefault()
              )
            drag: (event, ui) =>
              event.stopPropagation()
              @x = @zoom.translate_x_back(ui.offset.left)
              @y = @zoom.translate_y_back(ui.offset.top)
              simulation.take_hostage({
                id: @id
                x: @x
                y: @y
              })
              if not simulation.running
                simulation.redraw_lines()
            stop: (event, ui) =>
              if @temporary_highlight? and @temporary_highlight
                @click()
              @temporary_highlight = no
              @hostage = no
              event.stopPropagation()
              setTimeout(
                ->
                  ui.helper.unbind("click.prevent")
                300
              )
              if not @pinned
                simulation.release_hostage({
                  id: @id
                })
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
    s = [@data.description, @data.location, @data.screen_name, @data.name]
    if @data.status
      if @data.status.text
        s.push(@data.status.text)
    s.join(" ")
  randomize_position: (amount = -1) ->
    if amount > -1
      @x += Math.random() * amount - amount / 2
      @y += Math.random() * amount - amount / 2
    else
      @x = Math.random()*innerWidth
      @y = Math.random()*innerHeight
  click: (event) ->
    if event? and event.ctrlKey
      for id, f of simulation.friends when f.highlight
        f.highlight = not f.highlight
        f.div.toggleClass('highlight')
    else if event? and event.shiftKey
      for id, f of simulation.friends when id of @friends and not f.highlight
        f.highlight = not f.highlight
        f.div.toggleClass('highlight')
    @highlight = !@highlight
    @div.toggleClass('highlight')
    simulation.redraw_lines()
    simulation.check_expand_button()
  
  dblclick: =>
    @pinned = not @pinned
    if @pinned
      @div.addClass('pinned')
      simulation.take_hostage({
        id: @id
        x: @x
        y: @y
      })
    else
      simulation.release_hostage({
        id: @id
      })
      @div.removeClass('pinned')

    #    if confirm "Would you like to add the friends of @#{ @data.screen_name }?"
    #  if confirm "Clear the current field?"
    #    simulation.clear()
    #  simulation.add_protagonist(@data.screen_name)

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
