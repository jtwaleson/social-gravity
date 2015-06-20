// Generated by CoffeeScript 1.3.3
(function() {

  window.update_overlay = function() {
    var b_x, b_y, box_x, box_y, div, f, friend, friends, grid_size, he, i, id, info_item, j, lines, max_word, max_word_score, max_x, max_y, min_x, min_y, points, score, wi, word, words, _i, _j, _ref, _results;
    $('#information_overlay .info').remove();
    if (!$("#insight_button").is('.active')) {
      return;
    }
    grid_size = 100;
    wi = Math.round($("body").width() / grid_size);
    he = Math.round($("body").height() / grid_size);
    points = {};
    for (i = _i = 0; 0 <= wi ? _i <= wi : _i >= wi; i = 0 <= wi ? ++_i : --_i) {
      points[i] = {};
      for (j = _j = 0; 0 <= he ? _j <= he : _j >= he; j = 0 <= he ? ++_j : --_j) {
        points[i][j] = [];
      }
    }
    min_x = simulation.zoom.translate_x_back(0);
    min_y = simulation.zoom.translate_y_back(0);
    max_x = simulation.zoom.translate_x_back($("body").width());
    max_y = simulation.zoom.translate_y_back($("body").height());
    _ref = simulation.friends;
    for (id in _ref) {
      friend = _ref[id];
      box_x = Math.round(simulation.zoom.translate_x(friend.x) / grid_size);
      box_y = Math.round(simulation.zoom.translate_y(friend.y) / grid_size);
      b_x = box_x;
      b_y = box_y;
      if ((0 < b_x && b_x < wi) && (0 < b_y && b_y < he)) {
        points[b_x][b_y].push(friend);
      }
    }
    div = $("#information_overlay");
    _results = [];
    for (i in points) {
      lines = points[i];
      _results.push((function() {
        var _k, _l, _len, _len1, _ref1, _results1;
        _results1 = [];
        for (j in lines) {
          friends = lines[j];
          words = {};
          for (_k = 0, _len = friends.length; _k < _len; _k++) {
            f = friends[_k];
            _ref1 = f.words_list;
            for (_l = 0, _len1 = _ref1.length; _l < _len1; _l++) {
              word = _ref1[_l];
              if (!(word in words)) {
                words[word] = 0;
              }
              words[word] += 1;
            }
          }
          max_word = null;
          max_word_score = 0;
          for (word in words) {
            score = words[word];
            if (score > 1) {
              if (score > max_word_score) {
                max_word = word;
                max_word_score = score;
              }
            }
          }
          if (max_word != null) {
            info_item = $("<div>").addClass('info').text(max_word).css('left', i * grid_size).css('top', j * grid_size);
            div.append(info_item);
            _results1.push(info_item.css('margin-left', info_item.width() / -2));
          } else {
            _results1.push(void 0);
          }
        }
        return _results1;
      })());
    }
    return _results;
  };

  $(function() {
    var button, div;
    div = $("<div>").appendTo('body').hide().attr('id', 'information_overlay');
    button = new Button(3, "?", "Words overlay", "o", "", function() {
      div.toggle();
      $(this).toggleClass('active');
      return update_overlay();
    });
    return button.div.attr('id', 'insight_button');
  });

}).call(this);
