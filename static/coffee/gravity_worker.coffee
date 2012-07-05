center_x = 0
center_y = 0
friends = {}
hostages = {}
number_of_followers = {}
max_number_of_followers = 0
previous_number = {}
stop = no
run = no
move = (a, b, amount, proportional=no) ->
  if a.id of hostages
    return
  if b.id of hostages and not proportional
    amount *= 4

  dx = a.x - b.x
  dy = a.y - b.y

  if dx == 0
    dx = 0.001
  if dy == 0
    dy = 0.001
  
  distancesq = dx*dx + dy*dy
  boundary = 200
  boundarysq = boundary*boundary

#  postMessage({console: [dx,dy, distancesq, boundarysq]})

  if proportional
    if distancesq < boundarysq
      amount *= Math.min(5, Math.abs(1 / (distancesq / boundarysq )))
    else
      return
  else
    if distancesq > amount*amount
      amount = Math.sqrt(distancesq) / 2

   #   return

  angle = Math.atan2(dx, dy)


  add_x = amount * Math.sin(angle)
  add_y = amount * Math.cos(angle)

  friends[a.id].x -= add_x
  friends[a.id].y -= add_y

start = ->
#    postMessage({console: friends})
  mutual = 10
  follower = 4
  friend = 2
  move_away = 2
  for idA, friendA of friends
#    move(friendA, center_x, center_y, 1)
    for idB, friendB of friends when idB > idA
      if idA of friendB.friends and idB of friendA.friends
        move(friendB, friendA, mutual)
        move(friendA, friendB, mutual)
      else if idB of friendA.friends
        move(friendA, friendB, follower)
        move(friendB, friendA, friend)
      else if idA of friendB.friends
        move(friendA, friendB, friend)
        move(friendB, friendA, follower)
#      else
      move(friendA, friendB, -move_away, yes)
      move(friendB, friendA, -move_away, yes)
      
  list = for k,i of friends
    {id: i.id, x: i.x, y:i.y}
  postMessage(list)

randomize = (friend) ->
  friend.x += Math.random()*4 - 2
  friend.y += Math.random()*4 - 2
  
@onmessage = (event) ->
  if 'new_friend' of event.data
    friends[event.data.new_friend] = {x: event.data.x, y: event.data.y, id: event.data.new_friend, friends: event.data.friends}
    for id, _ of event.data.friends
      if id not of number_of_followers
        number_of_followers[id] = 0
      number_of_followers[id] += 1
      if id of friends and number_of_followers[id] > max_number_of_followers
        max_number_of_followers = number_of_followers[id]
    max_log = Math.log(max_number_of_followers)
    result = {}
    min_visibility = 0.4
    for id, _ of friends
      result[id] = Math.round(10 * (min_visibility + (Math.log(number_of_followers[id]) / max_log) * (1 - min_visibility)))
    final_results = {}
    for id, num of result
      if id not of previous_number or previous_number[id] != num
        final_results[id] = num
        previous_number[id] = num
    postMessage({popularity: final_results})
  else if 'clear' of event.data
    friends = {}
    hostages = {}
    number_of_followers = {}
    max_number_of_followers = 0
    previous_number = {}
  else if 'continue' of event.data
    start()
  else if 'release_hostage' of event.data
    delete hostages[event.data.release_hostage]
  else if 'force_x' of event.data
    hostages[event.data.id] = 0
    friends[event.data.id].x = event.data.force_x
    friends[event.data.id].y = event.data.force_y
  else if 'start' of event.data
    start()
  else if 'new_x' of event.data
    friends[event.data.id].x = event.data.new_x
    friends[event.data.id].y = event.data.new_y
  else if 'who_is_popular_here' of event.data
    max_distance = 150
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
      
