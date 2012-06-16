// Generated by CoffeeScript 1.3.3
(function() {
  var Friend;

  Friend = (function() {

    function Friend(id) {
      var _this = this;
      this.id = id;
      this.div = $("<div>").addClass('friend').appendTo("body").text(this.id).attr('id', this.id).bind('click', function(event) {
        return _this.click();
      }).bind('dblclick', function(event) {
        return _this.dblclick();
      });
    }

    Friend.prototype.click = function() {
      return this.div.css('background-color', 'black');
    };

    Friend.prototype.dblclick = function() {
      return this.div.css('background-color', 'red');
    };

    return Friend;

  })();

  $(function() {
    var jouke, steph;
    jouke = new Friend(1);
    return steph = new Friend(2);
  });

}).call(this);
