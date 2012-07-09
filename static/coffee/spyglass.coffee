class Spyglass
  constructor: ->
    @last_x = 0
    @last_y = 0
    @overlay = $("<div>")
      .attr("id", "spyglass_overlay")
      .hide()
      .appendTo("body")
      .mousemove((event) =>
        dx = @last_x - event.pageX
        dy = @last_y - event.pageY
        @glow.css('left', event.pageX)
        @glow.css('top', event.pageY)
        d = Math.sqrt(dx*dx + dy*dy)
        if d > 25
          @last_x = event.pageX
          @last_y = event.pageY
          simulation.who_is_popular_here(simulation.zoom.translate_x_back(event.pageX),simulation.zoom.translate_y_back(event.pageY))
      )
    @glow = $("<div>")
      .attr("id", "spyglass_glow")
      .appendTo(@overlay)
    @who_to_follow_wrapper = $("<div>")
      .attr("id", "who_to_follow_wrapper")
      .appendTo(@glow)
    @words_wrapper = $("<div>")
      .attr("id", "words_wrapper")
      .appendTo(@glow)
    @words = $("<ul>")
      .attr("id", "words")
      .appendTo(@words_wrapper)
    @who_to_follow_ul = $("<ul>")
      .attr("id", "who_to_follow")
      .appendTo(@who_to_follow_wrapper)
    
$ ->
  spyglass = new Spyglass
  new Button(3, "&#x22B9;", "Find new interesting people in an area", "i", "", ->
    spyglass.overlay.toggle()
    $(@).toggleClass("active")
  )
