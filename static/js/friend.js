// Generated by CoffeeScript 1.3.3
(function() {
  var Friend;

  Friend = (function() {

    function Friend(data) {
      var _this = this;
      if (data.friends.length === 1) {
        this.friends = data.friends[0].ids;
      } else {
        this.friends = [];
      }
      this.id = data.id;
      this.x = Math.random() * 1800;
      this.y = Math.random() * 800;
      this.div = $("<div>").addClass('friend').appendTo("#playfield").attr('id', this.id).bind('click', function(event) {
        return _this.click();
      }).bind('dblclick', function(event) {
        return _this.dblclick();
      });
      $("<img>").attr('src', data.profile_image_url).appendTo(this.div);
      $("<div>").text(data.name).addClass("name").appendTo(this.div);
      this.reposition();
      simulation.register(this);
      friends[this.id] = this;
    }

    Friend.prototype.click = function() {
      var ctx, i, other, otherpos, pos, _i, _len, _ref;
      this.div.css('background-color', 'black');
      ctx = $("#canvas")[0].getContext("2d");
      pos = this.div.position();
      pos.left += this.div.width() / 2;
      pos.top += this.div.height() / 2;
      ctx.beginPath();
      ctx.lineWidth = 3;
      _ref = this.friends;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        other = $("#" + i);
        if (other.length > 0) {
          otherpos = other.position();
          otherpos.left += other.width() / 2;
          otherpos.top += other.height() / 2;
          ctx.moveTo(pos.left, pos.top);
          ctx.lineTo(otherpos.left, otherpos.top);
        }
      }
      ctx.strokeStyle = '#000';
      return ctx.stroke();
    };

    Friend.prototype.dblclick = function() {
      return this.div.css('background-color', 'red');
    };

    Friend.prototype.setX = function(x) {
      this.x = x;
      return this.reposition();
    };

    Friend.prototype.setY = function(y) {
      this.y = y;
      return this.reposition();
    };

    Friend.prototype.reposition = function() {
      return this.div.css('top', this.y).css('left', this.x);
    };

    return Friend;

  })();

  window.Friend = Friend;

  window.friends = {};

}).call(this);
