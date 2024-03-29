// Generated by CoffeeScript 1.3.3
(function() {
  var center_x, center_y, friends, hostages, max_number_of_followers, move, number_of_followers, previous_number, randomize, run, start, stop;

  center_x = 0;

  center_y = 0;

  friends = {};

  hostages = {};

  number_of_followers = {};

  max_number_of_followers = 0;

  previous_number = {};

  stop = false;

  run = false;

  move = function(a, b, amount, proportional) {
    var add_x, add_y, angle, boundary, boundarysq, distancesq, dx, dy;
    if (proportional == null) {
      proportional = false;
    }
    if (a.id in hostages) {
      return;
    }
    if (b.id in hostages && !proportional) {
      amount *= 4;
    }
    dx = a.x - b.x;
    dy = a.y - b.y;
    if (dx === 0) {
      dx = 0.001;
    }
    if (dy === 0) {
      dy = 0.001;
    }
    distancesq = dx * dx + dy * dy;
    boundary = 200;
    boundarysq = boundary * boundary;
    if (proportional) {
      if (distancesq < boundarysq) {
        amount *= Math.min(5, Math.abs(1 / (distancesq / boundarysq)));
      } else {
        return;
      }
    } else {
      if (distancesq > amount * amount) {
        amount = Math.sqrt(distancesq) / 2;
      }
    }
    angle = Math.atan2(dx, dy);
    add_x = amount * Math.sin(angle);
    add_y = amount * Math.cos(angle);
    friends[a.id].x -= add_x;
    return friends[a.id].y -= add_y;
  };

  start = function() {
    var follower, friend, friendA, friendB, i, idA, idB, k, list, move_away, mutual;
    mutual = 10;
    follower = 4;
    friend = 2;
    move_away = 2;
    for (idA in friends) {
      friendA = friends[idA];
      for (idB in friends) {
        friendB = friends[idB];
        if (!(idB > idA)) {
          continue;
        }
        if (idA in friendB.friends && idB in friendA.friends) {
          move(friendB, friendA, mutual);
          move(friendA, friendB, mutual);
        } else if (idB in friendA.friends) {
          move(friendA, friendB, follower);
          move(friendB, friendA, friend);
        } else if (idA in friendB.friends) {
          move(friendA, friendB, friend);
          move(friendB, friendA, follower);
        }
        move(friendA, friendB, -move_away, true);
        move(friendB, friendA, -move_away, true);
      }
    }
    list = (function() {
      var _results;
      _results = [];
      for (k in friends) {
        i = friends[k];
        _results.push({
          id: i.id,
          x: i.x,
          y: i.y
        });
      }
      return _results;
    })();
    return postMessage(list);
  };

  randomize = function(friend) {
    friend.x += Math.random() * 4 - 2;
    return friend.y += Math.random() * 4 - 2;
  };

  this.onmessage = function(event) {
    var bottom, f, final_results, friend, guys, id, left, max_distance, max_log, min_visibility, num, popu, popular_guys, r, result, right, top, x, y, _, _i, _len, _ref, _ref1, _ref2, _ref3;
    if ('new_friend' in event.data) {
      friends[event.data.new_friend] = {
        x: event.data.x,
        y: event.data.y,
        id: event.data.new_friend,
        friends: event.data.friends
      };
      if (!(event.data.new_friend in number_of_followers)) {
        number_of_followers[event.data.new_friend] = 1;
      }
      _ref = event.data.friends;
      for (id in _ref) {
        _ = _ref[id];
        if (!(id in number_of_followers)) {
          number_of_followers[id] = 0;
        }
        number_of_followers[id] += 1;
        if (id in friends && number_of_followers[id] > max_number_of_followers) {
          max_number_of_followers = number_of_followers[id];
        }
      }
      max_log = Math.log(max_number_of_followers);
      result = {};
      min_visibility = 0.4;
      for (id in friends) {
        _ = friends[id];
        result[id] = Math.round(10 * (min_visibility + (Math.log(number_of_followers[id]) / max_log) * (1 - min_visibility)));
      }
      final_results = {};
      for (id in result) {
        num = result[id];
        if (!(id in previous_number) || previous_number[id] !== num) {
          final_results[id] = num;
          previous_number[id] = num;
        }
      }
      return postMessage({
        popularity: final_results
      });
    } else if ('clear' in event.data) {
      friends = {};
      hostages = {};
      number_of_followers = {};
      max_number_of_followers = 0;
      return previous_number = {};
    } else if ('continue' in event.data) {
      return start();
    } else if ('release_hostage' in event.data) {
      return delete hostages[event.data.release_hostage];
    } else if ('force_x' in event.data) {
      hostages[event.data.id] = 0;
      friends[event.data.id].x = event.data.force_x;
      return friends[event.data.id].y = event.data.force_y;
    } else if ('start' in event.data) {
      return start();
    } else if ('new_x' in event.data) {
      friends[event.data.id].x = event.data.new_x;
      return friends[event.data.id].y = event.data.new_y;
    } else if ('who_is_popular_here' in event.data) {
      max_distance = 150;
      guys = [];
      r = max_distance * event.data.zoom;
      x = event.data.x;
      y = event.data.y;
      left = x - r;
      right = x + r;
      top = y - r;
      bottom = y + r;
      for (id in friends) {
        f = friends[id];
        if (!((left < (_ref1 = f.x) && _ref1 < right) && (top < (_ref2 = f.y) && _ref2 < bottom))) {
          continue;
        }
        f.distance = (x - f.x) * (x - f.x) + (y - f.y) * (y - f.y);
        if (f.distance < r * r) {
          guys.push(f);
        }
      }
      guys.sort(function(a, b) {
        return a.distance - b.distance;
      });
      popular_guys = {};
      for (_i = 0, _len = guys.length; _i < _len; _i++) {
        friend = guys[_i];
        _ref3 = friend.friends;
        for (id in _ref3) {
          f = _ref3[id];
          if (!(!(id in friends))) {
            continue;
          }
          if (!(id in popular_guys)) {
            popular_guys[id] = 0;
          }
          popular_guys[id] += max_distance * max_distance - friend.distance;
        }
      }
      popu = (function() {
        var _results;
        _results = [];
        for (id in popular_guys) {
          f = popular_guys[id];
          _results.push({
            id: id,
            score: f
          });
        }
        return _results;
      })();
      popu.sort(function(a, b) {
        return b.score - a.score;
      });
      popu = popu.slice(0, 51);
      guys = (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = guys.length; _j < _len1; _j++) {
          f = guys[_j];
          _results.push(f.id);
        }
        return _results;
      })();
      return postMessage({
        guys: guys,
        popular_guys: popu
      });
    }
  };

}).call(this);
