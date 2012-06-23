friends = {}
stop = no
run = no
move = (a, b_x, b_y, amount) ->
  dx = a.x - b_x
  dy = a.y - b_y

  if dx == 0 and dy == 0
    return
  if dx == 0
    dx = 0.001
  if dy == 0
    dy = 0.001
  
  d = dx*dx + dy*dy

  if dx*dx > dy*dy
    px = 1
    py = Math.abs(dy/dx)
  else
    px = Math.abs(dx/dy)
    py = 1

  if dx < 0
    px *= -1
  if dy < 0
    py *= -1

  mx = amount*px
  my = amount*py

  if Math.abs(mx) > Math.abs(dx)
    mx = dx
  if Math.abs(my) > Math.abs(dy)
    my = dy

  friends[a.id].x -= mx
  friends[a.id].y -= my

start = ->
  if stop
    stop = no
    run = no
    return
  for idA, friendA of friends
    for idB, friendB of friends
      if idA of friendB.friends and idB of friendA.friends
        move(friendB, friendA.x, friendA.y, 5)
      else if idA of friendB.friends
        move(friendB, friendA.x, friendA.y, 1)
      else
        move(friendA, friendB.y, friendB.y, -0.3)
      
  list = for k,i of friends
    {id: i.id, x: i.x, y:i.y}
  postMessage(list)

randomize = (friend) ->
  friend.x += Math.random()*4 - 2
  friend.y += Math.random()*4 - 2
  postMessage([{id: friend.id, x: friend.x, y:friend.y}])
  
@onmessage = (event) ->
  if 'start_stop' of event.data
    if run
      event.data['stop'] = yes
    else
      event.data['start'] = yes

  if 'new_friend' of event.data
    friends[event.data.new_friend] = {x: event.data.x, y: event.data.y, id: event.data.new_friend, friends: {}}
    if 'friends' of event.data
      for f in event.data.friends
        friends[event.data.new_friend].friends[f] = 1
  else if 'continue' of event.data
    start()
  else if 'stop' of event.data
    run = no
    stop = yes
  else if 'start' of event.data
    run = yes
    start()
