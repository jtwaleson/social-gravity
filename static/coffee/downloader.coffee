class DownloadStatus

  constructor: (downloader, container) ->
    @downloader = downloader
    @div = $("<div>")
      .addClass('download_status')
      .hide()
      .appendTo(container)
    @failed_count = 0
    @queue = $("<span>").addClass('queue')
    @failed = $("<span>").addClass('failed')
    @success = $("<span>").addClass('success')
    @stopstart = $("<button>")
      .addClass("cancel")
      .click( =>
        @downloader.q.tasks = []
        @downloader.failed_downloads = 0
        @div.hide()
      )
      .html('stop downloading')
    @div.append(@queue).append(@failed).append(@success).append(@stopstart)
    @update()

  update: ->
    if @downloader.q.length() > 0
      @div.show()
      @queue.text "queued: #{ @downloader.q.length() }"
      if @downloader.failed_downloads > 0
        @failed.text "failed: #{ @downloader.failed_downloads } (DAMN YOU TWITTER API)"
      else
        @failed.text "failed: #{ @downloader.failed_downloads }"
      @success.text "success: #{ $(".friend").length }"
    else
      @div.hide()



class Downloader
  constructor: ->
    @no_more_twitter_count = 0
    @no_more_twitter = no
    @no_more_pipes = no
    @failed_downloads = 0
    @btn = new Button("@", "Add a new person of interest", "a", "glow", ->
      $(@).removeClass('glow')
      form = $("<form>")
        .insertAfter(@)
        .submit( (event) ->
          event.preventDefault()
          v = $(@).find('input[type=text]').val().toLowerCase().replace("@", "")
          if /[^a-z_0-9]/g.test(v)
            alert 'Not a valid twitter handle. Use letters, numbers and underscores only.'
          else
            load_friends = $(@).find('input[name=friends]').attr('checked')?
            load_self = $(@).find('input[name=self]').attr('checked')?
            simulation.add_protagonist(v, load_friends, load_self)
            $(@).remove()
        )
      $("<input>")
        .addClass("protagonist_adder")
        .attr("type", "text")
        .attr("placeholder", "@twitter_handle")
        .appendTo(form)
        .focus()
        .keyup( ->
          if event.keyCode == 27
            $(@).parent().remove()
        )
        .blur( ->
          if $(@).val().length == 0
            $(@).parent().remove()
        )
      for o in [
        {name: 'friends', text: 'Friends', default: yes}
        {name: 'self', text: 'Self', default: no}
      ]
        $("<label>")
          .attr('for', o.name)
          .text(o.text)
          .appendTo(form)
        $("<input>")
          .attr('name', o.name)
          .attr('value', '1')
          .attr('checked', o.default)
          .attr('type', 'checkbox')
          .appendTo(form)
      $("<input>").attr('type', 'submit').attr('value', 'Go!').appendTo(form)
    )

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
          '/cache/post/user/'+object.id
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
              '/cache/post/user/'+object.id
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
                downloader.status.update()
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
            alert "Done loading users. However, we failed to load #{ @failed_downloads } friends, probably due to twitter rate limiting. Come back in one hour to load more users."
          @failed_downloads = 0
          @no_more_twitter = no
          @no_more_twitter_count = 0
          @no_more_pipes = no
        1000
      )
    @status = new DownloadStatus(@, @btn.div.parent())
$ ->
  window.downloader = new Downloader
