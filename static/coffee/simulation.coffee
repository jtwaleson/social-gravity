class Simulation
  constructor: ->
    @gravity_worker = new Worker 'js/gravity_worker.js'
    @gravity_worker.onmessage = (event) =>
      for d in event.data
        friend = friends[d.id]
        friend.setX(d.x)
        friend.setY(d.y)
  register: (friend) ->
    @gravity_worker.postMessage({new_friend: friend.id, x: friend.x, y: friend.y, friends: friend.friends})
  start: ->
    @gravity_worker.postMessage({start: yes})
  stop: ->
    @gravity_worker.postMessage({stop: yes})
  

window.simulation = new Simulation

$ ->
  btn = $("<button>")
            .text("s")
            .click(
              (event) ->
                  if $(@).is('.started')
                    simulation.stop()
                  else
                    simulation.start()
                  $(@).toggleClass('started')
            )
                        
  li = $("<li>")
  li.append(btn)
  li.appendTo $("#menu")

  $('#playfield').mousewheel( (e, delta) ->
    console.log(e)
  )
