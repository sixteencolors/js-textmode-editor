class @Editor
  key =
    left: 37
    up: 38
    right: 39
    down: 40
    f1: 112
    f2: 113
    f3: 114
    f4: 115
    f5: 116
    f6: 117
    f7: 118
    f8: 119
    f9: 120
    f10: 121
    backspace: 8
    spacebar: 32
    delete: 46
    end: 35
    home: 36
    enter: 13
    escape: 27
    insert: 45
    h: 72
    l: 76
    s: 83,
    f: 70,
    ctrlF: 6,
    ctrlB: 2,
    ctrlX: 24,
    ctrlC: 3,
    ctrlZ: 26

  constructor: ( options ) ->
    @tabstop  = 8
    @id = 'canvas'
    @vga_id = 'vga'
    @vga_scale = '.25'
    @columns = 80
    this[k] = v for own k, v of options
    @expanded = false

  dbAuthenticate: ->

    @dbClient.authenticate interactive: false, (error, client) =>
      return @showError(error) if error
      if client.isAuthenticated()
        $("#DropboxSaveContainer").show()
        $("#DropboxFiles").show()
        $(".dropbox-login").hide()
        $("#LoadLogout").show()
        client.getUserInfo (error, userInfo) =>
          return @showError(error) if error
          $('.user-name').text userInfo.name
      else
        $("#DropboxSaveContainer").hide()
        $("#DropboxFiles").hide()
        $(".dropbox-login").show()
        $("#LoadLogout").hide()
        $(".dropbox-login").click =>
          client.authenticate (error, client) =>
            return @showError(error)  if error
            
            client.getUserInfo (error, userInfo) =>
              return @showError(error) if error
              $("#DropboxFiles").show()
              $("#DropboxSaveContainer").show()
              $(".dropbox-login").hide()
              $('.user-name').text userInfo.name
              @updateDrawingList()
              console.log "authenticated to dropbox as #{userInfo.name}" if window.console
    $('.logout').click (event) => @onSignOut event

  # Called when the user wants to sign out of the application.
  onSignOut: (event, task) ->
    @dbClient.signOut (error) =>
      return @showError(error) if error
      $("#DropboxSaveContainer").hide()
      $("#LoadLogout").hide()
      $("#DropboxFiles").hide()
      $(".dropbox-login").show()

  # Updates the UI to show that an error has occurred.
  showError: (error) ->
    $('#ErrorDialog').slideToggle 'slow'
    $("#ErrorDialog .message").text(error)
    console.log error if window.console

  init: ->
    @image = new ImageTextModeANSI
    @image.font = new ImageTextModeFont8x16
    @dbClient = new Dropbox.Client(key: config.dropbox.key, sandbox: true)
    @dbClient.authDriver(new Dropbox.Drivers.Popup({ rememberUser: true, receiverFile: "oauth_receiver.html"}));
    @dbAuthenticate()

    @manager = new BufferedUndoManager buffer: 1000
    @manager.on 'undo redo', () =>
      @image.screen = []
      $.extend @image.screen, @manager.state
      @draw()

    # @dbClient.authDriver new Dropbox.Drivers.Redirect(rememberUser: true)

    @canvas = document.getElementById @id
    @width = @image.font.width * @columns
    @canvas.setAttribute 'width', @width
    @vga_canvas = document.getElementById @vga_id
    @vga_canvas.setAttribute 'width', @width * @vga_scale
    @drawingId = null
    @block = {start: {x: 0, y: 0}, end: {x: 0, y: 0}, mode: 'off'}

    @drawings = $.parseJSON($.Storage.get("drawings"))


    @cursor = new Cursor
    @cursor.init @
    @pal = new Palette
    @pal.init @
    @sets = new CharacterSets
    @sets.init @
    
    @ctx = @canvas.getContext '2d' if @canvas.getContext
    @vga_ctx = @vga_canvas.getContext '2d' if @vga_canvas.getContext
    @setHeight($(window).height() + @image.font.height)

    @draw()

    $('#help').click =>
      @toggleSplash()

    $('#clear').click =>
      answer = confirm 'Clear canvas?'
      if (answer)
        @drawingId = null
        @image.screen = []
        @manager.reset()
        @draw()
        @setName("")

    $('#save').click =>
        @toggleSaveDialog()
        @drawings =[] if !@drawings
        if @drawings[@drawingId] then @setName(@drawings[@drawingId].name)

        @dbAuthenticate()

    $('#about').click =>
      @toggleAboutDialog()

    $('#notes').click =>
      @toggleReleaseNotesDialog()

    $('#html5Save').click =>
        # window.open(@canvas.toDataURL("image/png"), 'ansiSave')
        @drawings[@getId()] = {grid: @image.screen, date: new Date(), name: $('#name').val()}
        $.Storage.set("drawings", JSON.stringify(@drawings))
        @toggleSaveDialog()

    $('#PNGSave').click =>
        window.open(@canvas.toDataURL("image/png"), 'ansiSave')
        
    $('#DropboxSave').click =>
        @dbClient.writeFile 'ansi/' + $('#name').val(), @image.write(), (error, stat) =>
            return @showError(error) if error
            @toggleSaveDialog()


    $('#load').click =>
        @toggleLoadDialog()

    $("#canvasscroller").scroll (e) => # Increase canvas side if user scrolls past edge of screen
        if (e.target.clientHeight + @getScrollOffset() >= @height)
            @setHeight(@height + @image.font.height)
        @cursor.draw()
        if @cursor.mousedown
            $(this).trigger "moveblock"
        $("#vgahighlight").css('top', @getScrollOffset() * @vga_scale)

    $("body").bind "keyup", (e) =>
        # is in block mode, shift has been released and a key other then shift is pressed
        if @block.mode == 'on' && !e.shiftKey && e.which not in [key.shift, key.ctrl, key["delete"], key.backspace] 
            $(this).trigger "endblock"
        else if e.which == key.backspace 
          return false

    $("body").bind "keydown", (e) =>
        prevention = false

        if @block.mode == 'on' and e.which in [key["delete"], key.backspace]
            @delete()
        else if (e.target.nodeName != "INPUT")
            mod = e.altKey || e.ctrlKey
            if e.shiftKey && ((e.which >= key.left &&  e.which <= key.down) || (e.which >= key.end && e.which <= key.home ))
                if @block.mode == 'off'
                    $(this).trigger("startblock", [@cursor.x, @cursor.y, @getLinesOffset()])

            switch e.which
                when key.left
                    if (!mod)
                        @cursor.moveLeft()
                    else if e.ctrlKey || e.shiftKey #for now, mac os x has command for ctrl-right
                        if @pal.bg < 7 then @pal.bg++ else @pal.bg = 0
                when key.right
                    if (!mod)
                        @cursor.moveRight()
                    else if e.ctrlKey || e.shiftKey
                        if @pal.bg > 0 then @pal.bg-- else @pal.bg = 7
                when key.down
                    prevention = true
                    if (!mod)
                        @cursor.moveDown()
                    else if (e.ctrlKey)
                        if @pal.fg < 15 then @pal.fg++ else @pal.fg = 0
                when key.up
                    prevention = true
                    if (!mod)
                        @cursor.moveUp()
                    else if e.ctrlKey
                        if @pal.fg > 0 then @pal.fg-- else @pal.fg = 15
                when key.spacebar
                  @cursor.moveRight()
                  e.preventDefault()
                when key.backspace || key["delete"]
                    @cursor.moveLeft()
                    if @cursor.mode == 'ovr'
                        @putChar(32)
                        @cursor.moveLeft()
                    else
                        oldrow = @image.screen[@cursor.y]
                        @image.screen[@cursor.y] = oldrow[0..@cursor.x-1].concat(oldrow[@cursor.x+1..oldrow.length-1])
                    e.preventDefault()
                    return false
                when key.delete
                    oldrow = @image.screen[@cursor.y]
                    @image.screen[@cursor.y] = oldrow[0..@cursor.x-1].concat(oldrow[@cursor.x+1..oldrow.length-1])
                when key.end
                    @cursor.x = parseInt(@width / @image.font.width - 1)
                when key.home
                    @cursor.x = 0
                when key.enter
                    if @block.mode in ['copy', 'cut']
                        @paste()
                    else
                        @cursor.x = 0
                        @cursor.y++
                when key.insert
                    @cursor.change_mode()
                when key.escape
                    if $( '#splash' ).is( ':visible' )
                         $( '#splash' ).slideToggle 'slow'
                    if $( '#drawings' ).is( ':visible' )
                        $( '#drawings' ).slideToggle 'slow'
                    if $( '#SaveDialog' ).is( ':visible' )
                        $( '#SaveDialog' ).slideToggle 'slow'
                    if $( '#ErrorDialog').is(':visible')
                        $('#ErrorDialog').slideToggle 'slow'
                    if $( '#AboutDialog').is(':visible')
                      $('#AboutDialog').slideToggle 'slow'
                    if $( '#ReleaseNotesDialog').slideToggle 'slow'
                      $('#ReleaseNotesDialog').slideToggle 'slow'
                    if $('#CharacterSetDialog').is(':visible')
                        $('#CharacterSetDialog').slideToggle 'slow'
                    if @block.mode in ['copy', 'cut']
                        if @block.mode is 'cut'
                            @cancelCut()
                        $( '#copy' ).remove()
                        $(this).trigger("endblock")
                else 
                    if e.which == key.h && e.altKey
                      @toggleHelpDialog()
                      e.preventDefault()
                    if e.which == key.l && e.altKey
                      @updateDrawingList()
                      @toggleLoadDialog()
                      e.preventDefault()
                    if e.which == key.f && e.altKey
                      @toggleCharacterSetDialog()
                      e.preventDefault()
                    if e.which == key.s && e.altKey
                      @toggleSaveDialog()
                      e.preventDefault()                       

                    else if e.which >= 112 && e.which <= 121
                        if !e.altKey && !e.shiftKey && !e.ctrlKey
                            @putChar(@sets.sets[ @sets.set ][e.which-112])
                        else if e.altKey
                            @sets.set = e.which - 112
                            @sets.fadeSet()
                        e.preventDefault()


            @updateCursorPosition()
            if e.shiftKey && ((e.which >= key.left &&  e.which <= key.down) || (e.which >= key.end && e.which <= key.home )) && @block.mode == 'on'
                $(this).trigger("moveblock")

            @pal.draw()
            @cursor.draw()

            if (prevention)
                e.preventDefault
                return false

      # fix for ie loading help on F1 keypress
      if document.all
          window.onhelp = () -> return false
          document.onhelp = () -> return false

      $(this).bind "startblock", (e, x, y, offset) =>
          @block = {start: {x: x, y: y, offset: offset}, end: {x: x, y: y, offset: offset}, mode: 'on'}
          $("#highlight").css('display', 'block')
          $(this).trigger "moveblock"

      $(this).bind "endblock", (e) =>
          @block.mode = 'off'
          $("#highlight").css('display', 'none')
          @copyGrid = []

      $(this).bind "moveblock", (e) =>
          adjustedStartY = @block.start.y + @block.start.offset - @getLinesOffset()
          $("#highlight").css('left', (if @cursor.x >= @block.start.x then @block.start.x else @cursor.x) * @image.font.width)
          $("#highlight").css('top', ((if @cursor.y >= adjustedStartY then adjustedStartY else @cursor.y)  ) * @image.font.height)
          $("#highlight").width (Math.abs(@cursor.x - @block.start.x) + 1) * @image.font.width
          $("#highlight").height (Math.abs(@cursor.y - adjustedStartY) + 1) * @image.font.height

      $("body").bind "keypress", (e) =>       
        if @block.mode is 'on' and e.ctrlKey
          switch e.which
            when key.ctrlF # fill foreground
              @fillBlock(@pal.fg, null)
              @draw()
            when key.ctrlB # fill background
              @fillBlock(null, @pal.bg)
              @draw()            
            when key.ctrlX # cut
              @setBlockEnd()
              @cut()
            when key.ctrlC # copy
              @setBlockEnd()
              @copy()

        else if e.target.nodeName != "INPUT"
          char = String.fromCharCode(e.which)
          pattern = ///
            [\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>/\?`';~\-\s:"]
          ///
          if char.match(pattern) && e.which <= 255 && !e.ctrlKey && e.which != 13
            @putChar(char.charCodeAt( 0 ) & 255);  
          else if e.which == key.ctrlZ and !e.shiftKey
            @manager.undo()
          else if e.which == key.ctrlZ and e.shiftKey
            @manager.redo()

      $('#' + @id).mousemove ( e ) =>
          if @cursor.mousedown
              @setMouseCoordinates(e)
              @putChar(@sets.char, true) if @sets.locked
              @updateCursorPosition()
              if @block.mode == 'off' && !sets.locked
                  $(this).trigger("startblock", [@cursor.x, @cursor.y, @getLinesOffset()])
              else if !@sets.locked
                  $(this).trigger("moveblock")
              return true
          if @block.mode in ['copy', 'cut']
              @setMouseCoordinates(e)
              @positionCopy()


      $('#' + @id).mousedown ( e ) => # Pablo only moves the cursor on click, this feels a little better when used -- may need to re-evaluate for touch usage
          return unless e.which == 1
          @cursor.mousedown = true
          @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left ) / @image.font.width ) 
          @cursor.y = Math.floor( (e.pageY - $('#' + @id).offset().top ) / @image.font.height )
          @putChar(@sets.char, true) if @sets.locked
          @cursor.draw()
          @updateCursorPosition()
          $(this).trigger("endblock") if @block.mode not in ['copy', 'cut']

          return true

      $('#' + @id).bind 'touchstart', ( e ) =>            
          e.preventDefault()
          if (e.originalEvent.touches.length == 1)
              return @putTouchChar(e.originalEvent.touches[0])
          

      $('#' + @id).bind 'touchmove', ( e ) =>
          if (e.originalEvent.touches.length == 1) # Only if one finger
              touch = e.originalEvent.touches[0] # Get the information for finger #1        
              return @putTouchChar( touch )

      $('body').mouseup ( e ) =>
          if @block.mode in ['copy', 'cut']
              @paste()

          @cursor.mousedown = false
          @cursor.draw()

      $(window).resize ( e ) =>
          @width = @canvas.clientWidth
          @height = @canvas.clientHeight
          @canvas.setAttribute 'width', @width
          @canvas.setAttribute 'height', @height
          @draw() 

  getScrollOffset: ->
      $("#canvasscroller").scrollTop()

  getLinesOffset: ->
      Math.floor(@getScrollOffset() / @image.font.height)

  setHeight: (height, copy = true) ->
      $('#canvaswrapper').height($(window).height())
      $('#canvasscroller').height($(window).height())

      if (height < $(window).height() + @image.font.height)
          height = $(window).height() + @image.font.height

      if (height > @height or !@height?)
          @height = height
          if (copy)
              tempCanvas = @canvas.toDataURL("image/png")
              tempImg = new Image()
              tempImg.src = tempCanvas
              $(tempImg).load =>
                  @canvas.setAttribute 'height', @height
                  @ctx.drawImage(tempImg, 0, 0)
                  @renderCanvas()
          else
              @canvas.setAttribute 'height', @height

          @vga_canvas.setAttribute 'height', @height
          console.log("Height updated to " + @height + "px")
          # @draw()



  setBlockEnd: ->
      @block.end.y = @cursor.y
      @block.end.x = @cursor.x


  copy: ->
      @block.mode = 'copy'
      @copyOrCut()

  cut: ->
      @block.mode = 'cut'
      @copyOrCut(true, true)

  delete: ->
      @copyOrCut(false, true)
      $(this).trigger("endblock")


  cancelCut: ->
      if @block.end.y > @block.start.y 
          starty = @block.start.y
          endy = @block.end.y
      else 
          starty = @block.end.y
          endy = @block.start.y

      if @block.end.x > @block.start.x
          startx = @block.start.x
          endx = @block.end.x
      else
          startx = @block.end.x
          endx = @block.start.x

      yy = 0;
      for y in [ starty .. endy ]
          xx = 0;
          for x in [ startx .. endx ]
              # adjustedY = y - Math.abs(@cursor.y - @block.start.y)
              # adjustedX = x - Math.abs(@cursor.x - @block.start.x)
              @image.screen[y][x] = { ch: @copyGrid[yy][xx].ch, attr: @copyGrid[yy][xx].attr } if @copyGrid[yy][xx]?
              xx++
          yy++

      $('#copy').remove()
      @draw()

  copyOrCut: (copy = true, cut=false)->
      @copyGrid = []
      if @cursor.y > @block.start.y 
          starty = @block.start.y
          endy = @cursor.y
      else 
          starty = @cursor.y
          endy = @block.start.y

      if @cursor.x > @block.start.x
          startx = @block.start.x
          endx = @cursor.x
      else
          startx = @cursor.x
          endx = @block.start.x

      if copy
          adjustedStartY = @block.start.y + @block.start.offset 
          adjustedY = @cursor.y + @getLinesOffset()
          sourceWidth = (Math.abs(@cursor.x - @block.start.x) + 1) * @image.font.width
          sourceHeight = (Math.abs(adjustedY - adjustedStartY) + 1) * @image.font.height

          # make copy of portion of canvas
          @copyCanvas = document.createElement('canvas')
          @copyCanvas.id = 'copy'
          @copyCanvasContext = @copyCanvas.getContext '2d' if @copyCanvas.getContext                
          @copyCanvas.setAttribute 'width', sourceWidth 
          @copyCanvas.setAttribute 'height', sourceHeight

          @cursor.x = if @cursor.x >= @block.start.x then @block.start.x else @cursor.x
          @cursor.y = if adjustedY >= adjustedStartY then adjustedStartY else adjustedY
          sourceX = @cursor.x * @image.font.width 
          sourceY = @cursor.y * @image.font.height 
          @cursor.y -= @getLinesOffset()
          destWidth = sourceWidth
          destHeight = sourceHeight
          destX = 0
          destY = 0

          @copyCanvasContext.drawImage(@canvas, sourceX, sourceY, sourceWidth, sourceHeight, destX, destY, destWidth, destHeight)
          $(@copyCanvas).insertBefore('#vgawrapper')

      # make copy of drawing data

      yy = 0;
      for y in [ starty .. endy ]
          xx = 0;
          for x in [ startx .. endx ]
              # adjustedY = y - Math.abs(@cursor.y - @block.start.y)
              # adjustedX = x - Math.abs(@cursor.x - @block.start.x)

              if !@copyGrid[yy]?
                  @copyGrid[yy] = []
              @copyGrid[yy][xx] = { ch: @image.screen[y][x].ch, attr: @image.screen[y][x].attr } if @image.screen[y][x]? and copy
              @image.screen[y][x] = { ch: ' ', attr: ( 0 << 4 ) | 0 } if (cut && @image.screen[y][x]?)  # clear block if cutting
              xx++
          yy++

      @draw() if cut


      @positionCopy()

  paste: ->
      # place copy
      stationaryY = @cursor.y
      stationaryX = @cursor.x

      for y in [ 0 .. @copyGrid.length - 1]
          continue if !@copyGrid[y]?
          for x in [0 .. @copyGrid[y].length - 1]
              continue if !@copyGrid[y][x]?
              if !@image.screen[stationaryY + y]?
                  @image.screen[stationaryY + y] = []
              @image.screen[stationaryY + y][stationaryX + x] = { ch: @copyGrid[y][x].ch, attr: @copyGrid[y][x].attr } if @copyGrid[y][x]?
      @draw()

      $('#copy').remove()
      $(this).trigger("endblock")

  setMouseCoordinates: (e) ->
      @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left ) / @image.font.width )
      @cursor.y = Math.floor( e.pageY / @image.font.height )

  positionCopy: ->
      $(@copyCanvas).css('left', @cursor.x  * @image.font.width)
      $(@copyCanvas).css('top', (@cursor.y) * @image.font.height)
          
  fillBlock: (fg, bg) ->
      for y in [@block.start.y..@cursor.y]
          continue if !@image.screen[y]?
          for x in [(@cursor.x)..@block.start.x]
              continue if !@image.screen[y][x]?
              @image.screen[y][x].attr = ( (if bg then bg  else ( @image.screen[y][x].attr & 240 ) >> 4 )<< 4 ) | if fg then fg else @image.screen[y][x].attr & 15


  setName: (name) ->
    $('#name').val( name )

  toggleCharacterSetDialog: ->
    unless $('#CharacterSetDialog').is(':visible')
      $( '#drawings').slideUp 'slow'
      $( '#splash' ).slideUp 'slow'
      $( '#SaveDialog').slideUp 'slow'
      $( '#AboutDialog' ).slideUp 'slow'
      $( '#ReleaseNotesDialog').slideUp 'slow'
    $('#CharacterSetDialog').slideToggle('slow')

  toggleSplash: ->
    unless $('#splash').is(':visible')
      $( '#drawings').slideUp 'slow'
      $( '#splash' ).slideUp 'slow'
      $( '#SaveDialog').slideUp 'slow'
      $( '#AboutDialog' ).slideUp 'slow'
      $( '#ReleaseNotesDialog').slideUp 'slow'
    $('#splash').slideToggle('slow')

  toggleSaveDialog: ->
    unless $( '#SaveDialog' ).is( ':visible' )
      $( '#drawings').slideUp 'slow'
      $( '#splash' ).slideUp 'slow'
      $( '#AboutDialog' ).slideUp 'slow'
      $( '#ReleaseNotesDialog').slideUp 'slow'
    $( '#SaveDialog' ).slideToggle 'slow'

  toggleLoadDialog: ->
    unless $( '#drawings' ).is( ':visible' )
      @updateDrawingList()
      $( '#SaveDialog').slideUp 'slow'
      $( '#splash' ).slideUp 'slow'
      $( '#AboutDialog' ).slideUp 'slow'
      $( '#ReleaseNotesDialog').slideUp 'slow'
    $( '#drawings' ).slideToggle 'slow'

  toggleHelpDialog: ->
    unless $( '#splash' ).is( ':visible' )
      $( '#drawings').slideUp 'slow'
      $( '#SaveDialog' ).slideUp 'slow'
      $( '#AboutDialog' ).slideUp 'slow'
      $( '#ReleaseNotesDialog').slideUp 'slow'
    $( '#splash' ).slideToggle 'slow'

  toggleAboutDialog: ->
    unless $( '#AboutDialog' ).is(':visible' )
      $( '#drawings').slideUp 'slow'
      $( '#splash' ).slideUp 'slow'
      $( '#SaveDialog').slideUp 'slow'
      $( '#ReleaseNotesDialog').slideUp 'slow'
    $( '#AboutDialog' ).slideToggle 'slow'      

  toggleReleaseNotesDialog: ->
    unless $( '#ReleaseNotesDialog' ).is(':visible' )
      $( '#drawings').slideUp 'slow'
      $( '#splash' ).slideUp 'slow'
      $( '#SaveDialog').slideUp 'slow'
      $( '#AboutDialog').slideUp 'slow'
    $( '#ReleaseNotesDialog' ).slideToggle 'slow'      

  toggleErrorDialog: ->
    $('#ErrorDialog').slideToggle 'slow'

  updateDrawingList: ->
      $('#drawings #html5Files ol').empty()
      @drawings =[] if !@drawings
      @addDrawing drawing, i for drawing, i in @drawings

      $('#drawings #html5Files li span.name').click (e) =>
          @drawingId = $( e.currentTarget ).parent().attr( "nid" )
          @image.screen = @drawings[ @drawingId ].grid
          @height = 0
          @setHeight(@image.screen.length * @image.font.height, false)
          @draw()
          @toggleLoadDialog()

      $('#drawings #html5Files li span.delete').click (e) =>
          answer = confirm 'Delete drawing?'
          if (answer)
              @drawings[$( e.currentTarget ).parent().attr("nid")] = null
              $.Storage.set("drawings", JSON.stringify(@drawings))
              @updateDrawingList()

      if @dbClient.isAuthenticated()
          $("#drawings #DropboxFiles").empty()
          @dbClient.mkdir '/ansi', (error, stat) =>
              # Issued mkdir so we always have a directory to read from.
              # In most cases, this will fail, so don't bother checking for errors.
              @dbClient.readdir '/ansi', (error, entries, dir_stat, entry_stats) =>
                  #return @showError(error) if error
                  console.log error if error and window.console                    
                  $('#DropboxFiles').append("<li nid=\"#{entry.name}\"><span class=\"name\">#{entry.name}</span> <span class=\"delete\"></span>") for entry in entry_stats
          
                  $('#DropboxFiles span.name').click (e) =>
                      @dbClient.readFile "ansi/#{$(e.target).text()}", arrayBuffer: true, (error, data) =>
                          return @showError(error) if error
                          @image.parse(@binaryArrayToString data)
                          @manager.reset($.extend(true, {}, @image.screen))
                          @setHeight(@image.getHeight() * @image.font.height, false)
                          @draw()
                          @toggleLoadDialog()


  addDrawing: ( drawing, id ) ->
      if drawing
          $('#drawings #html5Files ol').append( '<li nid=' + id + '><span class="name">' + (if drawing.name then drawing.name else $.format.date(drawing.date, "MM/dd/yyyy hh:mm:ss a")) + '</span> <span class="delete">X</span></li>')

  getId: ->
      
      return if @drawingId then @drawingId else @generateId()

  generateId: ->
      return if @drawings then @drawings.length else 1
          
  updateCursorPosition: ->
      $( '#cursorpos' ).text '[ L:' + (@cursor.y + 1) + ' C:' + (@cursor.x + 1) + ' ]'
 

  putTouchChar: ( touch ) ->
      node = touch.target
      @cursor.x = Math.floor( ( touch.pageX - $('#' + @id).offset().left )  / @image.font.width )
      @cursor.y = Math.floor( (touch.pageY - $('#' + @id).offset().top )/ @image.font.height )
      @putChar(@sets.char) if @sets.locked
      @drawChar(@cursor.x, @cursor.y)
      @updateCursorPosition()
      return true

  synchronize: ->
    if @manager?
      @image.screen = @manager.state
      @draw()

  putChar: (charCode, holdCursor = false) ->
    @image.screen[@cursor.y] = [] if !@image.screen[@cursor.y]
    if @cursor.mode == 'ins'
        # NOTE: this will push chars off the right-side of the canvas
        # but will still have an entry in the grid
        row = @image.screen[@cursor.y][@cursor.x..]
        @image.screen[@cursor.y][@cursor.x + 1..] = row
    @image.screen[@cursor.y][@cursor.x] = { ch: String.fromCharCode( charCode ), attr: ( @pal.bg << 4 ) | @pal.fg }

    screencopy = $.extend(true, {}, @image.screen)
    @manager.update $.extend(true, {}, @image.screen)

    @drawChar(@cursor.x, @cursor.y)
    unless holdCursor then @cursor.moveRight()
    @updateCursorPosition()

  loadUrl: ( url ) ->
      req = new XMLHttpRequest
      req.open 'GET', url, false
      if req.overrideMimeType
          req.overrideMimeType 'text/plain; charset=x-user-defined'
      req.send null
      content = if req.status is 200 or req.status is 0 then req.responseText else ''
      return content

  loadFont: ->
      return new ImageTextModeFont8x16

  drawChar: (x, y, full = false) ->
      if @image.screen[y][x]
          px = x * @image.font.width
          py = y * @image.font.height

          @ctx.fillStyle = @pal.toRgbaString( @image.palette.colors[ ( @image.screen[y][x].attr & 240 ) >> 4 ] ) #bg
          @ctx.fillRect px, py, 8, 16

          @ctx.fillStyle = @pal.toRgbaString( @image.palette.colors[ @image.screen[y][x].attr & 15 ] ) #fg
          chr = @image.font.chars[ @image.screen[y][x].ch.charCodeAt( 0 ) & 0xff  ]
          for i in [ 0 .. @image.font.height - 1 ]
              line = chr[ i ]
              for j in [ 0 .. @image.font.width - 1 ]
                  if line & ( 1 << 7 - j )
                      @ctx.fillRect px + j, py + i, 1, 1
          if !full #don't redraw on each character if it is a full canvas draw
              @renderCanvas()
      
  draw: ->
      @ctx.fillStyle = "#000000"
      @ctx.fillRect 0, 0, @canvas.width, @canvas.height
      @image.screen = [] if !@image.screen?
      for y in [0..@image.screen.length - 1]
          continue if !@image.screen[y]?
          for x in [0..@image.screen[y].length - 1]
              continue if !@image.screen[y][x]?
              @drawChar(x, y, true)

      @renderCanvas()

  renderCanvas: ->
      @ctx.fill()
      @vga_ctx.fillStyle = "#000000"
      @vga_ctx.fillRect 0, 0,  @canvas.width * @vga_scale, @canvas. height * @vga_scale
      @vga_ctx.drawImage(@canvas, 0, 0, @canvas.width, @canvas.height, 0, 0, @canvas.width * @vga_scale, @canvas. height * @vga_scale);
      highlight = $("#vgahighlight")
      highlight.width(@vga_canvas.getAttribute 'width')
      highlight.height($("#canvaswrapper").height() * @vga_scale)
      $("#vgawrapper").css('left', $("#toolbar").width() + $("#canvas").width())

  binaryArrayToString: (buf) ->
      String.fromCharCode.apply null, new Uint8Array(buf)

class Cursor

    constructor: ( options ) ->
        @x = 0
        @y = 0
        @mousedown = false
        @mode = 'ovr'
        @selector = $( '#cursor' )
        @offset = 0
        this[k] = v for own k, v of options

    init: ( @editor ) ->
        @draw()

    change_mode: ( mode ) ->
        if mode
            @selector.attr 'class', mode
        else 
            @selector.toggleClass 'ins'

        @mode = @selector.attr( 'class' ) || 'ovr'

    draw: ->
        width = @editor.image.font.width
        height = @editor.image.font.height
        @selector.css 'width', width
        @selector.css 'height', height
        @selector.css 'left', @x * width + 4 # 4 to accomodate border width
        @selector.css 'top', @y * height - @editor.getScrollOffset() + 4 # 4 to accomodate border width

    moveRight: ->
        if @x < @editor.width / @editor.image.font.width - 1
            @x++
        else if @y < @editor.height / @editor.image.font.height - 1
            @x =0
            @y++

        @move()


    moveLeft: ->
        if @x > 0
            @x--
        else if @y > 0
            @y--
            @x = @editor.width / @editor.image.font.width - 1
        
        @move()


    moveUp: ->
        if @y > 0                            
          @y--

        if @y * @editor.image.font.height < @getScrollOffset()
            $("#canvasscroller").scrollTop(@getScrollOffset() - @editor.image.font.height)

        @move()

    moveDown: ->
        if (@y >= parseInt(($(window).height() - @editor.image.font.height * 2) / @editor.image.font.height))
            $("#canvasscroller").scrollTop(@getScrollOffset() + @editor.image.font.height)

        @y++

        @move()

    move: ->
        if @editor.block.mode in ['copy', 'cut']
            @editor.positionCopy()
        @draw()


        
class CharacterSets

    constructor: ( options ) ->
        @sets = [
            [ 218, 191, 192, 217, 196, 179, 195, 180, 193, 194, ]
            [ 201, 187, 200, 188, 205, 186, 204, 185, 202, 203, ]
            [ 213, 184, 212, 190, 205, 179, 198, 181, 207, 209, ]
            [ 214, 183, 211, 189, 196, 186, 199, 182, 208, 210, ]
            [ 197, 206, 216, 215, 232, 232, 155, 156, 153, 239, ]
            [ 176, 177, 178, 219, 223, 220, 221, 222, 254, 250, ]
            [ 1, 2, 3, 4, 5, 6, 240, 14, 15, 32, ]
            [ 24, 25, 30, 31, 16, 17, 18, 29, 20, 21, ]
            [ 174, 175, 242, 243, 169, 170, 253, 246, 171, 172, ]
            [ 227, 241, 244, 245, 234, 157, 228, 248, 251, 252, ]
            [ 224, 225, 226, 229, 230, 231, 235, 236, 237, 238, ]
            [ 128, 135, 165, 164, 152, 159, 247, 249, 173, 168, ]
            [ 131, 132, 133, 160, 166, 134, 142, 143, 145, 146, ]
            [ 136, 137, 138, 130, 144, 140, 139, 141, 161, 158, ]
            [ 147, 148, 149, 162, 167, 150, 129, 151, 163, 154, ]
        ]
        @set = 5
        @charpos = 0
        @char = @sets[ @set ][ @charpos ]
        @locked = false
        this[k] = v for own k, v of options

    init: ( editor ) ->
        for i in [ 0 .. @sets.length - 1 ]
            set = $( '<li>' )
            set.data 'set', i
            chars = $( '<ul>' )

            for j in [ 0 .. @sets[ i ].length - 1 ]
                c = @sets[ i ][ j ]
                char = $( '<canvas>' )
                char.attr 'width', editor.image.font.width
                char.attr 'height', editor.image.font.height

                ctx = char[ 0 ].getContext '2d'
                ctx.fillStyle = '#fff'
                for y in [ 0 .. editor.image.font.height - 1 ]
                    line = editor.image.font.chars[ c ][ y ]
                    for x in [ 0 .. editor.image.font.width - 1 ]
                        if line & ( 1 << 7 - x )
                            ctx.fillRect x, y, 1, 1

                charwrap = $( '<li>' )
                charidentifier = $('<span>' + ( if j == 0 then 'F' else ' ' ) +  (j + 1) + ' </span>')
                charwrap.data 'char', c
                charwrap.data 'pos', j
                charwrap.append charidentifier
                charwrap.append char
                chars.append charwrap

            set.append chars
            $( '#sets' ).append set
        $( '#expand' ).click ( e ) =>
          @showAllSets()

        $( '#next-set' ).click ( e ) =>
            @set++
            @set = 0 if @set > 14
            @fadeSet()

        $( '#prev-set' ).click ( e ) =>
            @set--
            @set = 14 if @set < 0
            @fadeSet()

        $( '#char-lock' ).click ( e ) =>
            @locked = !@locked
            $( e.target ).toggleClass 'on'

        $( '#sets ul li' ).click ( e ) =>
            @char = $( e.currentTarget ).data 'char'
            @charpos = $( e.currentTarget ).data 'pos'
            $(@sets).each (i, set) =>
              @set = i if $.inArray(_this.char, set) > -1
            @hideSets()
            @fadeSet()            
            @draw()

        @draw()

    draw: ->
        sets = $( '#sets > li' )
        sets.hide()
        set = sets.filter( ':nth-child(' + ( @set + 1 ) + ')' )
        set.show()
        set.find( 'li' ).removeClass( 'selected' )
        set.find( 'li:nth-child(' + ( @charpos + 1 ) + ')' ).addClass( 'selected' )
        
    hideSets: ->
      @fadeSet()
      $('#toolbar').parent().removeClass('expanded')
      @expanded = false
      $('#next-set, #prev-set, #char-lock').show()
      # $('body').off('click', '#expand', @hideSets)
      # $('body').on('click', '#expand', @showAllSets)

    showAllSets: ->
      if !@expanded
        $('#next-set, #prev-set, #char-lock').hide()
        $('#toolbar').parent().addClass('expanded')
        $('#sets > li').fadeIn( 'fast')
        @expanded = true
      else 
        @hideSets()
      # $('body').on('click', '#expand', @hideSets)
      # $('body').off('click', '#expand', @showAllSets)


    fadeSet: ->
        $('#sets > li:visible' ).fadeOut( 'fast', () =>
            $('#sets > li:nth-child(' + ( @set + 1 ) + ')' ).fadeIn( 'fast' )
            @char = @sets[ @set ][ @charpos ]
            @draw()
        )

class Palette

    constructor: ( options ) ->
        @fg = 7
        @bg = 0
        this[k] = v for own k, v of options

    init: ( editor ) ->
        indicators = $( '#fg,#bg' )
        indicators.click ( e ) ->
            if !$( e.target ).hasClass( 'selected' )
                indicators.toggleClass( 'selected', 200 )

        $( '#colors' ).children().empty()
        $( '#colors' ).append '<ul class=first></ul>', '<ul></ul>'
        # d p
        # 0 0
        # 1 8
        # 2 4
        # 3 12
        # 4 2
        # 5 10
        # 6 6
        # 7 14
        # 8 1
        # 9 9
        # 10  5
        # 11  13
        # 12  3
        # 13  11
        # 14  7
        # 15  15   

        map = [ 0,
                8,
                4,
                12,
                2,
                10,
                6,
                14,
                1,
                9,
                5,
                13,
                3,
                11,
                7,
                15, 
        ];
        for o in [ 0 .. editor.image.palette.colors.length - 1 ]
            i = map[ o ]
            block = $( '<li>' )
            block.data 'color', i
            block.css 'background', @toRgbaString editor.image.palette.colors[ i ]
            if editor.image.palette.colors[ i ][ 0 ] == 0 and editor.image.palette.colors[ i ][ 1 ] == 0
              block.css 'color', @toRgbaString @invertColors editor.image.palette.colors[ i ]

            # set initial selections
            if i == @fg
              block.addClass "fg_selected"
            if i == @bg
              block.addClass "bg_selected"

            block.click ( e ) =>
                @[ indicators.filter( '#fg' ).attr 'id' ] = $( e.target ).data 'color'
                $('#colors ul li').each ->
                  $(this).removeClass "fg_selected"
                $(e.target).addClass('fg_selected');
                @draw()

            block.bind "contextmenu", (e) =>
                @[ indicators.filter( '#bg' ).attr 'id' ] = $( e.target ).data 'color'
                $('#colors ul li').each ->
                  $(this).removeClass "bg_selected"
                $(e.target).addClass('bg_selected');
                @draw()
                return false

            $( '#colors ul:nth-child(' + ( 1 + Math.round( i / ( editor.image.palette.colors.length - 1 ) ) ) + ')' ).append block
        @draw()

    draw: ->
        $( '#fg' ).css 'background-color', @toRgbaString editor.image.palette.colors[ @fg ]
        # $( '#fg' ).css 'color', @toRgbaString editor.image.palette.colors[ if @fg > 8 then 0 else 15 ]
        $( '#bg' ).css 'background-color', @toRgbaString editor.image.palette.colors[ @bg ]
        # $( '#bg' ).css 'color', @toRgbaString editor.image.palette.colors[ if @bg > 8 then 0 else 15 ]
        return true

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)'

    invertColors: (color) ->
      $.map color, (value, i) ->
        (value + 85)# % 255 # attempt to invert the colors for text on black/etc, may be very hacky


FileSelectHandler = ( e ) ->
    # fetch FileList object
    files = e.target.files || e.dataTransfer.files
    # process all File objects
    ParseFile file for file in files

AbortParse = ->
    @reader.abort()

ParseFile = ( file ) ->
  @reader = new FileReader()
  $( @reader ).load ( e ) ->
    progress = $(".percent")
    progress.width('100%')
    progress.text('100%')
    setTimeout("document.getElementById('progress_bar').className='';", 2000);

    editor.height = 0
    content = e.target.result
    start = new Date().getTime();
    console.log 'Begin parsing'
    progressIntervalID = setInterval ->
      end = new Date().getTime()
      console.log((end - start) + 's')
    , 1000

    editor.image.parse( content )
    editor.manager.reset($.extend(true, {}, editor.image.screen))
    clearInterval(progressIntervalID)
    console.log 'End parsing'
    editor.setHeight(editor.image.getHeight() * editor.image.font.height, false)
    editor.draw()
    editor.toggleLoadDialog()
    return true

  $( @reader ).error ( e ) ->
    switch e.target.error.code
      when e.target.error.NOT_FOUND_ERR
        alert "File Not Found!"
      when evt.target.error.NOT_READABLE_ERR
        alert "File is not readable"
      when evt.target.error.ABORT_ERR
      # noop
      else
        alert "An error occurred reading this file."

  $( @reader ).bind "progress", (e) ->
    if e.lengthComputable
      percentLoaded = Math.round((e.loaded / e.total) * 100)
      
      # Increase the progress bar length.
      if percentLoaded < 100
        progress.style.width = percentLoaded + "%"
        progress.textContent = percentLoaded + "%"        

  $( @reader ).bind "abort", (e) ->
    alert('File read cancelled')

  $( @reader ).bind  "loadstart", (e) -> 
    $("#progress_bar").addClass "loading"
    console.log ("load started" )

  editor.setName( file.name )
  @reader.readAsBinaryString(file)
  return false

$( document ).ready ->
  editor.init()

  $('.menu').dropit({action:'hover', triggerEl: 'h1'});

  editor.toggleHelpDialog()
  $( '#splash .close' ).click ->
    editor.toggleHelpDialog()
    return false

  $( '#drawings .close' ).click ->
    editor.toggleLoadDialog()
    return false

  $( '#SaveDialog .close' ).click ->
    editor.toggleSaveDialog()
    return false

  $( '#AboutDialog .close' ).click ->
    editor.toggleAboutDialog()
    return false

  $( '#ReleaseNotesDialog .close' ).click ->
    editor.toggleReleaseNotesDialog()
    return false

  $( '#CharacterSetDialog .close' ).click ->
    editor.toggleCharacterSetDialog()
    return false

  $( '#ErrorDialog .close').click ->
    editor.toggleErrorDialog()
    return false

  if (window.File && window.FileList && window.FileReader) 
    fileselect = $("#fileselect")
    # file select
    fileselect.change ( e ) -> 
      FileSelectHandler ( e )

    # is XHR2 available?
    return false

editor = new Editor
