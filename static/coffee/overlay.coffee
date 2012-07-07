$ ->
  div = $("<div>")
    .appendTo('body')
    .hide()
    .attr('id', 'information_overlay')

  button = new Button("Info", "Insight",  "o",  "", ->
    div.find('.info').remove()
    simulation.stop()
    div.toggle()
    $(@).toggleClass('active')
    if not $(@).is('.active')
      return
    grid_size = 100
    wi = Math.round($("body").width()/grid_size)
    he = Math.round($("body").height()/grid_size)
    points = {}
    for i in [0..wi]
      points[i] = {}
      for j in [0..he]
        points[i][j] = []
    min_x = simulation.zoom.translate_x_back(0)
    min_y = simulation.zoom.translate_y_back(0)
    max_x = simulation.zoom.translate_x_back($("body").width())
    max_y = simulation.zoom.translate_y_back($("body").height())

    for id, friend of simulation.friends
      box_x = Math.round(simulation.zoom.translate_x(friend.x) / grid_size)
      box_y = Math.round(simulation.zoom.translate_y(friend.y) / grid_size)
      b_x = box_x
      b_y = box_y
#      for b_x in [box_x-1..box_x+1]
#        for b_y in [box_y-1..box_y+1]
      if 0 < b_x < wi and 0 < b_y < he
        points[b_x][b_y].push(friend)
    for i, lines of points
      for j, friends of lines
        words = {}
        for f in friends
          for word in f.words_list
            if word not of words
              words[word] = 0
            words[word] += 1
        max_word = null
        max_word_score = 0
        for word, score of words
          if score > 1
            if score > max_word_score
              max_word = word
              max_word_score = score
        if max_word?
          div.append(
            $("<div>")
              .addClass('info')
              .text(max_word)
              .css('left', i*grid_size)
              .css('top', j*grid_size)
          )
  )
