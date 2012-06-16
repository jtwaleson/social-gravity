class Friend
  constructor: (@id) ->
    @div = $("<div>")
          .addClass('friend')
          .appendTo("body")
          .text(@id)
          .attr('id', @id)
          .bind('click', (event) => @click())
          .bind('dblclick', (event) => @dblclick())
  click: ->
    @div.css('background-color', 'black')
  dblclick: ->
    @div.css('background-color', 'red')

  
    

$ ->
  jouke = new Friend 1
  steph = new Friend 2
