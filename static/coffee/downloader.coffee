class Downloader
  constructor: ->
  
  _cache: (cacheUrl, success, error) ->
    $.ajax(
      url: cacheUrl
      dataType: 'json'
      type: 'GET'
      error: (xhr, textstatus, errorthrown) ->
        if xhr.status == 404
          error()
        else
          alert("Server cache error")
      success: (result, a, xhr) ->
        success(result)
    )

  _twitter: (twitterUrl, success, error) ->
    $.ajax(
      type: 'POST'
      url: twitterUrl
      dataType: "jsonp"
      success: (r,a,xhr) ->
        success(r)
      timeout: 5000
      error: error
    )

  _pipes: (twitterUrl, success, error) ->
    $.ajax(
      type: 'POST'
      data:
        _id: '81263ca2954c525a92e8ebe02b9c5a82'
        _render: 'json'
        url: twitterUrl
      url: 'http://pipes.yahoo.com/pipes/pipe.run'
      dataType: "jsonp"
      jsonp: "_callback"
      success: (r,a,xhr) ->
        if r['count'] > 0
          r = r['value']['items']
          success(r)
        else
          error()
      timeout: 5000
      error: error
    )
  _resolve: (cacheUrl, twitterUrl, success, error) ->
    @._cache(cacheUrl, success, => @._resolve_without_cache(twitterUrl, success, error))
    
  _resolve_without_cache: (twitterUrl, success, error) ->
    @._twitter(twitterUrl, success, => @._pipes(twitterUrl, success, error))

  by_user_name: (username, success, error) ->
    @._resolve(
      '/cache/userbyname/'+username.toLowerCase()
      'http://api.twitter.com/1/users/lookup.json?screen_name='+username,
      (data) =>
        if data[0]['protected'] == no or data[0]['protected'] == 'false'
          @.find_user(data, success, error)
        else
          error('Protected account, impossibru')
      =>
        error('Could not resolve')
    )

  by_user_id: (id, success, error) ->
    @._resolve(
      '/cache/user/'+id
      'http://api.twitter.com/1/users/lookup.json?user_id='+id,
      (data) =>
        @.find_user(data, success, error)
      =>
        error('Could not resolve')
    )

  find_user: (data, success, error) ->
    if data.length == 1
      data = data[0]
      if 'friends' of data
        success(data)
      else if data['protected'] is no or data['protected'] is 'false'
        @.find_friends(
          data
          success
          =>
            error('User found, but could not find friends')
        )
      else
        data.friends = []
        $.post(
          '/cache/user/'+data.id
          data: JSON.stringify(data)
        )
        success(data)

  find_friends: (profile, success, error) ->
    @._resolve_without_cache(
      'http://api.twitter.com/1/friends/ids.json?cursor=-1&user_id='+profile['id_str']
      (data) =>
        profile['friends'] = data
        $.post(
          '/cache/user/'+profile.id
          data: JSON.stringify(profile)
        )
        success(profile)
      error
    )

$ ->
  downloader = new Downloader
  new Button("@", "a", "glow", ->
    $(@).removeClass('glow')
    downloader.by_user_name(
      'jtwaleson'
      (data) =>
        friend = new Friend(data)
        for id in data.friends[0].ids
          do (id) ->
            downloader.by_user_id(
              id
              (data) =>
                new Friend(data)
              (message) =>
                alert(message)
            )
      (message) =>
        alert(message)
    )
  )
