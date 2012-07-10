$ ->
  div = $("#help_overlay")
  div.hide()
  div.mousedown( (e) ->
    e.stopPropagation()
  )
  div.mouseup( (e) ->
    e.stopPropagation()
  )
  div.mousewheel( (e, delta) ->
    e.stopPropagation()
  )
  button = new Button(4, "What!?", "Wtf is this crap?",  "w",  "", ->
    div.toggle()
    $(@).toggleClass('active')
  )
