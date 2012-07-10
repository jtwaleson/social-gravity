$ ->
  div = $("#help_overlay")
  div.hide()
  div.draggable({
    helper: () =>
      $("<div>").css('position','absolute').css('width', '100px').css('height', '100px')
    stop: (e) ->
      e.stopPropagation()
    start: (e) ->
      e.stopPropagation()
    drag: (e) ->
      e.stopPropagation()
  })
  div.mousewheel( (e, delta) ->
    e.stopPropagation()
  )

  button = new Button(4, "What!?", "Wtf is this crap?",  "w",  "", ->
    div.toggle()
    $(@).toggleClass('active')
  )
