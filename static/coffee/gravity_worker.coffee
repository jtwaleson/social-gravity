center_x = 0
center_y = 0
friends = {}
stop = no
run = no
move = (a, b_x, b_y, amount, proportional=no) ->
  dx = a.x - b_x
  dy = a.y - b_y

  if dx == 0 and dy == 0
    return
  if dx == 0
    dx = 0.001
  if dy == 0
    dy = 0.001
  
  d = dx*dx + dy*dy
  dst = 400
  halfdst = dst/2

  if proportional
    if d < dst*dst
      if d < dst
        d = halfdst
      amount = amount * (halfdst*halfdst) / d
    else
      return
      

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
#    postMessage({console: friends})
    return
  for idA, friendA of friends
#    move(friendA, center_x, center_y, 1)
    for idB, friendB of friends
      if idA of friendB.friends and idB of friendA.friends
        move(friendB, friendA.x, friendA.y, 20)
      else if idA of friendB.friends
        move(friendB, friendA.x, friendA.y, 10)
#      else
      move(friendA, friendB.x, friendB.y, -2, yes)
      
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
    friends[event.data.new_friend] = {x: event.data.x, y: event.data.y, id: event.data.new_friend, friends: event.data.friends}
  else if 'continue' of event.data
    start()
  else if 'stop' of event.data
    run = no
    stop = yes
  else if 'start' of event.data
    run = yes
    start()
  else if 'new_x' of event.data
    friends[event.data.id].x = event.data.new_x
    friends[event.data.id].y = event.data.new_y
