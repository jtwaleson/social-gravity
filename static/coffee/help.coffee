$ ->
  div = $("<div>")
    .appendTo('body')
    .hide()
    .attr('id', 'help_overlay')

  button = new Button(4, "What!?", "Wtf is this crap?",  "w",  "", ->
    div.toggle()
    $(@).toggleClass('active')
  )
