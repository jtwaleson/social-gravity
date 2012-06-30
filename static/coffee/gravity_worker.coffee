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
  dst = 200
  halfdst = dst/2

  if proportional
    if d < dst*dst
      if d < dst
        d = dst
      amount = amount * (halfdst*halfdst) / d
    else
      return
  else
    if d < (dst*dst) / 2
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
#    postMessage({console: friends})
  for idA, friendA of friends
#    move(friendA, center_x, center_y, 1)
    for idB, friendB of friends
      if idA of friendB.friends and idB of friendA.friends
        move(friendB, friendA.x, friendA.y, 10)
      else if idA of friendB.friends
        move(friendB, friendA.x, friendA.y, 5)
      else
        move(friendA, friendB.x, friendB.y, -1, yes)
      
  list = for k,i of friends
    {id: i.id, x: i.x, y:i.y}
  postMessage(list)

randomize = (friend) ->
  friend.x += Math.random()*4 - 2
  friend.y += Math.random()*4 - 2
  postMessage([{id: friend.id, x: friend.x, y:friend.y}])
  
@onmessage = (event) ->
  if 'new_friend' of event.data
    friends[event.data.new_friend] = {x: event.data.x, y: event.data.y, id: event.data.new_friend, friends: event.data.friends}
  else if 'clear' of event.data
    friends = {}
  else if 'continue' of event.data
    start()
  else if 'force_x' of event.data
    friends[event.data.id].x = event.data.force_x
    friends[event.data.id].y = event.data.force_y
  else if 'start' of event.data
    start()
  else if 'new_x' of event.data
    friends[event.data.id].x = event.data.new_x
    friends[event.data.id].y = event.data.new_y
  else if 'who_is_popular_here' of event.data
    max_distance = 50
    guys = []
    r = max_distance * event.data.zoom
    x = event.data.x
    y = event.data.y
    left   = x - r
    right  = x + r
    top    = y - r
    bottom = y + r
    for id, f of friends when left < f.x < right and top < f.y < bottom
      f.distance = (x - f.x) * (x - f.x) + (y - f.y) * (y - f.y)
      if f.distance < r*r
        guys.push(f)
    guys.sort( (a,b) ->
      a.distance - b.distance
    )
    popular_guys = {}
    for friend in guys
      for id, f of friend.friends when id not of friends
        if id not of popular_guys
          popular_guys[id] = 0
        popular_guys[id] += max_distance*max_distance - friend.distance

    popu = (id for id, f of popular_guys)
    popu.sort( (a,b) ->
      popular_guys[b] - popular_guys[a]
    )
    popu = popu[0..5]
    popu2 = {}
    for id in popu
      popu2[id] = popular_guys[id]

    guys = (f.id for f in guys)
    postMessage({guys: guys, popular_guys: popu2})
      
