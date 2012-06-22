class Spyglass
  constructor: ->
    @overlay = $("<div>")
      .attr("id", "spyglass_overlay")
      .hide()
      .appendTo("body")
      .mousemove((event) =>
        @glow.css('left', event.pageX)
        @glow.css('top', event.pageY)
        @who_to_follow.text(
          simulation.zoom.translate_x_back(event.pageX) +
          " - " +
          simulation.zoom.translate_y_back(event.pageY))
        console.log(event)
      )
    @glow = $("<div>")
      .attr("id", "spyglass_glow")
      .appendTo(@overlay)
    @who_to_follow = $("<div>")
      .attr("id", "who_to_follow")
      .appendTo(@glow)
    
$ ->
  spyglass = new Spyglass
  new Button("i", "", ->
    spyglass.overlay.toggle()
    $(@).toggleClass("active")
  )