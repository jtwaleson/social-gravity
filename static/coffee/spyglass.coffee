class Spyglass
  constructor: ->
    @last_x = 0
    @last_y = 0
    @overlay = $("<div>")
      .attr("id", "spyglass_overlay")
      .hide()
      .appendTo("body")
    @glow = $("<div>")
      .attr("id", "spyglass_glow")
      .appendTo(@overlay)
      .html('<br/><br/>drag')
      .draggable({
        drag: (e, ui) =>
          event = e.originalEvent
          dx = @last_x - event.pageX
          dy = @last_y - event.pageY
          @glow.css('left', event.pageX)
          @glow.css('top', event.pageY)
          d = Math.sqrt(dx*dx + dy*dy)
          if d > 25
            @last_x = event.pageX
            @last_y = event.pageY
            simulation.who_is_popular_here(simulation.zoom.translate_x_back(event.pageX),simulation.zoom.translate_y_back(event.pageY))
        start: (e, ui) =>
          @who_to_follow_ul.empty()
        stop: (e, ui) =>
          li = $("<li>")
            .addClass('btn')
          btn = $("<button>")
            .text("Follow suggestions?")
            .appendTo(li)
            .data('start_at', 0)
            .click( (event) ->
              ul = $(@).closest('ul')
              people = ul.data('who_to_follow')
              downloader.q.tasks = (item for item in downloader.q.tasks when not item.spyglass?)
              ul.find('li.follow_suggestion').remove()
              start_at = $(@).data('start_at')
              $(@).data('start_at', start_at+5)
              $(@).text('More...')
              if start_at + 5 > people.length
                $(@).remove()
              for user in people[start_at..start_at+4]
                do (user) ->
                  ul.find('li.btn').before(
                    $("<li>")
                      .text("?")
                      .attr('id', "you_should_follow_#{ user.id }")
                      .addClass('follow_suggestion')
                  )
                  downloader.q.push(
                    {id: user.id}
                    (result) ->
                      if result.error?
                        $("#you_should_follow_#{ user.id }").text('DAMN YOU TWITTER API')
                      else
                        result = result.result
                        $("#you_should_follow_#{ user.id }")
                          .empty()
                          .append(
                            $("<div>")
                              .addClass('follow_suggestion')
                              .html("<a target='_blank' href='https://twitter.com/#{ result.screen_name }'>@#{ result.screen_name }</a> - #{ result.description }")
                          )
                          .append($("<button>").text('+').addClass('add_to_field').click( ->
                            simulation.add_friend(user.id)
                          ))
                  )
            )
          @who_to_follow_ul.append(li)
          
      })
    @words = $("<ul>")
      .attr("id", "words")
      .appendTo(@glow)
    @who_is_here_ul = $("<ul>")
      .attr("id", "who_is_here")
      .appendTo(@glow)
    @who_to_follow_ul = $("<ul>")
      .attr("id", "who_to_follow")
      .appendTo(@glow)
  clear: ->
    @who_is_here_ul.empty()
    @words.empty()
    @who_to_follow_ul.empty()
  reset: ->
    @glow.css('left', $("body").width()/2)
    @glow.css('top', $("body").height()/2)
    @clear()
    
    
$ ->
  window.spyglass = new Spyglass
  new Button(3, "&#x22B9;", "Insight eye: Find which keywords are used in an area", "i", "", ->
    spyglass.overlay.toggle()
    $(@).toggleClass("active")
    if $(@).is('.active')
      spyglass.reset()
  )
