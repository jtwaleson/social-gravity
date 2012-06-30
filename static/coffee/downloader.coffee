class Downloader
  constructor: ->
    @no_more_twitter_count = 0
    @no_more_twitter = no
    @no_more_pipes = no
    @failed_downloads = 0

    @counter = $("<div>").appendTo("body").attr("id", "download_counter")

    try_cache = (task, callback) =>
      if task.name?
        url = "/cache/userbyname/#{ task.name.toLowerCase() }"
      else
        url = "/cache/user/#{ task.id }"
       
      $.ajax(
        url: url
        dataType: 'json'
        type: 'GET'
        error: (xhr, textstatus, errorthrown) ->
          if xhr.status == 404
            callback null, null
          else
            console.log("Server cache does not respond. This is bad...")
            callback null, null
        success: (result, a, xhr) ->
          f = result[0]
          f.protected = not (f.protected == 'false' or f.protected == no)
          callback f
      )

    try_twitter = (object, get_friends, task, callback) =>
      if get_friends and object? and (object.protected is 'true' or object.protected is true)
        object.friends = []
        $.post(
          '/cache/user/'+object.id
          data: JSON.stringify(object)
        )
        return callback object, null
      if @no_more_twitter_count > 4
        return callback null, object
      base_url = 'http://api.twitter.com/1'
      if get_friends
        if not (object? and object.id?)
          return callback null, 'Should not look get friends without user id'
        task.twitter_url = "#{ base_url }/friends/ids.json?cursor=-1&user_id=#{ object.id }"
      else if task.name?
        task.twitter_url = "#{ base_url }/users/lookup.json?screen_name=#{ task.name.toLowerCase() }"
      else
        task.twitter_url = "#{ base_url }/users/lookup.json?user_id=#{ task.id }"

      $.ajax(
        type: 'POST'
        url: task.twitter_url
        dataType: "jsonp"
        success: (r,a,xhr) =>
          @no_more_twitter_count = 0
          if get_friends
            object.friends = r
            $.post(
              '/cache/user/'+object.id
              data: JSON.stringify(object)
            )
            callback object, null
          else
            f = r[0]
            f.protected = not (f.protected == 'false' or f.protected == no)
            callback null, f
        timeout: 4000
        error: =>
          @no_more_twitter_count += 1
          callback null, object
      )

    try_pipes = (object, get_friends, task, callback) =>
      if @no_more_pipes
        return callback null, object
      $.ajax({
        type: 'POST'
        data:
          _id: '81263ca2954c525a92e8ebe02b9c5a82'
          _render: 'json'
          url: task.twitter_url
        url: 'http://pipes.yahoo.com/pipes/pipe.run'
        dataType: "jsonp"
        jsonp: "_callback"
        success: (r,a,xhr) ->
          if r['count'] > 0
            r = r['value']['items']
            if get_friends
              object.friends = r
              $.post(
                '/cache/user/'+object.id
                data: JSON.stringify(object)
              )
              return callback object, null
            else
              return callback null, r[0]
          else
            callback null, object
        timeout: 2000
        error: =>
          @no_more_pipes = yes
          callback null, object
      })

    #misusing the waterfall, we swap error and result. 
      # once the result is in, we throw an "error" to skip the rest. 
    @q = async.queue(
      (task, callback) ->
        setTimeout(
          ->
            async.waterfall(
              [
                (callback)         -> try_cache                     task, callback
                (object, callback) -> try_twitter           object, no,   task, callback
#                (object, callback) -> try_pipes             object, no,   task, callback
                (object, callback) -> try_twitter           object, yes,  task, callback
#                (object, callback) -> try_pipes             object, yes,  task, callback
                (object, callback) -> callback              null, "Could not complete result"
              ]
              (result, error) ->
                downloader.counter.text(downloader.q.length())
                if error?
                  callback {error: error}
                else
                  callback {result: result}
            )
          10
        )
      1
    )
    @q.drain = =>
      setTimeout(
        =>
          for id, friend of simulation.friends when friend.highlight
            friend.click()
          if @failed_downloads > 0
            error_report = " However, we failed to load #{ @failed_downloads } friends, probably due to twitter rate limiting. Come back in one hour to load more users."
          else
            error_report = ""
          alert "Done loading users.#{ error_report }"
          @failed_downloads = 0
          @no_more_twitter = no
          @no_more_twitter_count = 0
          @no_more_pipes = no
        1000
      )
$ ->
  window.downloader = new Downloader
  new Button("@", "Add a new person of interest", "a", "glow", ->
    $(@).removeClass('glow')
    $("<input>")
        .addClass("protagonist_adder")
        .attr("type", "text")
        .insertAfter(@)
        .focus()
        .change( ->
          if /[^a-z_0-9]/g.test($(@).val().toLowerCase())
            alert('Not a valid twitter handle. Use letters and underscores only.')
          else
            simulation.add_protagonist($(@).val())
            $(@).remove()
        )
        .keyup( (event) ->
          if event.keyCode == 27
            $(@).remove()
        )
        .blur( ->
          $(@).remove()
        )
  )
#        for id in data.friends[0].ids when id not of simulation.friends
#          do (id) ->
#            downloader.by_user_id(
#              id
#              (data) =>
#                new Friend(data)
#              (message) =>
#                alert(message)
#            )
#      (message) =>
#        alert(message)
