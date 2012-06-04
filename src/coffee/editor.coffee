class @Editor

    constructor: ( options ) ->
        @tabstop  = 8
        @id = 'canvas'
        @vga_id = 'vga'
        @vga_scale = '.25'
        this[k] = v for own k, v of options

    init: ->
        @font = @loadFont()
        @canvas = document.getElementById @id
        @width = @canvas.clientWidth 
        @height = @canvas.clientHeight
        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height
        @vga_canvas = document.getElementById @vga_id
        @vga_canvas.setAttribute 'width', @width * @vga_scale
        @vga_canvas.setAttribute 'height', @height
        @grid = []
        @drawingId = null

        @drawings = $.parseJSON($.Storage.get("drawings"))

        @cursor = new Cursor
        @cursor.init @
        @pal = new Palette
        @pal.init @
        @sets = new CharacterSets
        @sets.init @
        
        @ctx = @canvas.getContext '2d' if @canvas.getContext
        @vga_ctx = @vga_canvas.getContext '2d' if @vga_canvas.getContext

        @draw()

        $('#clear').click =>
            answer = confirm 'Clear canvas?'
            if (answer)
                @drawingId = null
                @grid = []
                @draw()
                @setName("")

        $('#save').click =>
            @toggleSaveDialog()
            @drawings =[] if !@drawings
            if @drawings[@drawingId] then @setName(@drawings[@drawingId].name)

        $('#html5Save').click =>
            # window.open(@canvas.toDataURL("image/png"), 'ansiSave')
            @drawings[@getId()] = {grid: @grid, date: new Date(), name: $('#name').val()}
            $.Storage.set("drawings", JSON.stringify(@drawings))
            @toggleSaveDialog()

        $('#PNGSave').click =>
            window.open(@canvas.toDataURL("image/png"), 'ansiSave')
            
        $('#load').click =>
            @toggleLoadDialog()

        $("body").bind "keydown", (e) =>
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
              delete: 46
              end: 35
              home: 36
              enter: 13
              escape: 27
              insert: 45
              h: 72
              l: 76
              s: 83

            if (e.target.nodeName != "INPUT")
                mod = e.shiftKey || e.altKey || e.ctrlKey
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
                        if (!mod)
                            if @cursor.y < (@height - 16) / 16
                              @cursor.y++
                        else if (e.ctrlKey)
                            if @pal.fg < 15 then @pal.fg++ else @pal.fg = 0
                    when key.up
                        if (!mod)
                            if @cursor.y > 0
                              @cursor.y--
                              @cursor.draw()
                        else if e.ctrlKey
                            if @pal.fg > 0 then @pal.fg-- else @pal.fg = 15
                    when key.backspace
                        @cursor.moveLeft()
                        if @cursor.mode == 'ovr'
                            @putChar(32)
                            @cursor.moveLeft()
                        else
                            oldrow = @grid[@cursor.y]
                            @grid[@cursor.y] = oldrow[0..@cursor.x-1].concat(oldrow[@cursor.x+1..oldrow.length-1])
                        e.preventDefault()
                    when key.delete
                        oldrow = @grid[@cursor.y]
                        @grid[@cursor.y] = oldrow[0..@cursor.x-1].concat(oldrow[@cursor.x+1..oldrow.length-1])
                    when key.end
                        @cursor.x = parseInt(@width / @font.width - 1)
                    when key.home
                        @cursor.x = 0
                    when key.enter
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
                    else 
                        if e.which == key.h && e.altKey
                            @toggleHelpDialog()
                            e.preventDefault()

                        if e.which == key.l && e.altKey
                            @updateDrawingList()
                            @toggleLoadDialog()
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
                @pal.draw()
                @cursor.draw()

        # file select
        if (window.File && window.FileList && window.FileReader) 
            fileselect = $("#fileselect")
            fileselect.change ( e ) -> 
                FileSelectHandler ( e )

        # fix for ie loading help on F1 keypress
        if document.all
            window.onhelp = () -> return false
            document.onhelp = () -> return false

        $("body").bind "keypress", (e) =>       
            if (e.target.nodeName != "INPUT")     
                char = String.fromCharCode(e.which)
                pattern = ///
                    [\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>/\?`~\-\s]
                ///
                if char.match(pattern) && e.which <= 255 && !e.ctrlKey && e.which != 13
                    @putChar(char.charCodeAt( 0 ) & 255);                    

        $('#' + @id).mousemove ( e ) =>
            if @cursor.mousedown
                @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left ) / @font.width )
                @cursor.y = Math.floor( e.pageY / @font.height )
                @putChar(@sets.char, true) if @sets.locked
                @updateCursorPosition()
                return true


        $('#' + @id).mousedown ( e ) => # Pablo only moves the cursor on click, this feels a little better when used -- may need to re-evaluate for touch usage
            return unless e.which == 1
            @cursor.mousedown = true
            @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left ) / @font.width ) 
            @cursor.y = Math.floor( e.pageY / @font.height )
            @putChar(@sets.char, true) if @sets.locked
            @cursor.draw()
            @updateCursorPosition()
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
            @cursor.mousedown = false
            @cursor.draw()

        $(window).resize ( e ) =>
            @width = @canvas.clientWidth
            @height = @canvas.clientHeight
            @canvas.setAttribute 'width', @width
            @canvas.setAttribute 'height', @height
            @draw() 

        $( '#dialogs .close' ).click ( e ) =>
            @toggleDialog $( e.currentTarget ).parent().attr 'class'

    setName: (name) ->
        $('#name').val( name )

    toggleDialog: ( name ) ->
        dialog = $( '#dialogs .' + name )

        if dialog.is( ':visible' )
            dialog.parent().slideToggle 'slow', () ->
                dialog.toggle()
        else
            dialog.toggle 0, () ->
                # @updateDrawingList()
                dialog.parent().slideToggle 'slow'

    updateDrawingList: ->
        $('#drawings ol').empty()
        @drawings =[] if !@drawings
        @addDrawing drawing, i for drawing, i in @drawings

        $('#drawings li span.name').click (e) =>
            @drawingId = $( e.currentTarget ).parent().attr( "nid" )
            @grid = @drawings[ @drawingId ].grid
            @draw()
            @toggleLoadDialog()

        $('#drawings li span.delete').click (e) =>
            answer = confirm 'Delete drawing?'
            if (answer)
                @drawings[$( e.currentTarget ).parent().attr("nid")] = null
                $.Storage.set("drawings", JSON.stringify(@drawings))
                @updateDrawingList()

    addDrawing: ( drawing, id ) ->
        if drawing
            $('#drawings ol').append( '<li nid=' + id + '><span class="name">' + (if drawing.name then drawing.name else $.format.date(drawing.date, "MM/dd/yyyy hh:mm:ss a")) + '</span> <span class="delete">X</span></li>')

    getId: ->
        
        return if @drawingId then @drawingId else @generateId()

    generateId: ->
        return if @drawings then @drawings.length else 1
            
    updateCursorPosition: ->
        $( '#cursorpos' ).text '(' + (@cursor.x + 1) + ', ' + (@cursor.y + 1) + ')'
   

    putTouchChar: ( touch ) ->
        node = touch.target
        @cursor.x = Math.floor( ( touch.pageX - $('#' + @id).offset().left )  / @font.width )
        @cursor.y = Math.floor( touch.pageY / @font.height )
        @putChar(@sets.char) if @sets.locked
        @drawChar(@cursor.x, @cursor.y)
        @updateCursorPosition()
        return true

    putChar: (charCode, holdCursor = false) ->
        @grid[@cursor.y] = [] if !@grid[@cursor.y]
        if @cursor.mode == 'ins'
            # NOTE: this will push chars off the right-side of the canvas
            # but will still have an entry in the grid
            row = @grid[@cursor.y][@cursor.x..]
            @grid[@cursor.y][@cursor.x + 1..] = row
        @grid[@cursor.y][@cursor.x] = { ch: String.fromCharCode( charCode ), attr: ( @pal.bg << 4 ) | @pal.fg }
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
        return new Font8x16

    drawChar: (x, y, full = false) ->
        if @grid[y][x]
            px = x * @font.width
            py = y * @font.height

            @ctx.fillStyle = @pal.toRgbaString( @pal.colors[ ( @grid[y][x].attr & 240 ) >> 4 ] ) #bg
            @ctx.fillRect px, py, 8, 16

            @ctx.fillStyle = @pal.toRgbaString( @pal.colors[ @grid[y][x].attr & 15 ] ) #fg
            chr = @font.chars[ @grid[y][x].ch.charCodeAt( 0 ) & 0xff  ]
            for i in [ 0 .. @font.height - 1 ]
                line = chr[ i ]
                for j in [ 0 .. @font.width - 1 ]
                    if line & ( 1 << 7 - j )
                        @ctx.fillRect px + j, py + i, 1, 1
            if !full #don't redraw on each character if it is a full canvas draw
                @renderCanvas()
        
    draw: ->
        @ctx.fillStyle = "#000000"
        @ctx.fillRect 0, 0, @canvas.width, @canvas.height
        for y in [0..@grid.length - 1]
            continue if !@grid[y]?
            for x in [0..@grid[y].length - 1]
                continue if !@grid[y][x]?
                @drawChar(x, y, true)

        @renderCanvas()

    renderCanvas: ->
        @ctx.fill()
        @vga_ctx.fillStyle = "#000000"
        @vga_ctx.fillRect 0, 0,  @canvas.width * @vga_scale, @canvas. height * @vga_scale
        @vga_ctx.drawImage(@canvas, 0, 0, @canvas.width, @canvas.height, 0, 0, @canvas.width * @vga_scale, @canvas. height * @vga_scale);
        
FileSelectHandler = ( e ) ->
    # fetch FileList object
    files = e.target.files || e.dataTransfer.files
    # process all File objects
    ParseFile file for file in files

ParseFile = ( file ) ->
    reader = new FileReader()
    $( reader ).load ( e ) ->
        console.log( e.target.result )
        content = e.target.result
        image = new ImageTextModeANSI()
        image.parse( content )
        editor.grid = image.screen
        editor.draw()
        editor.toggleLoadDialog()
        return true

    $( reader ).error ( e ) ->
        console.log ( "error loading file" )

    $( reader ).bind  "loadstart", (e) -> 
        console.log ("load started" )

    editor.setName( file.name )
    reader.readAsBinaryString(file)
    return false

$( document ).ready ->
    editor = new Editor
    editor.init()
    editor.toggleDialog 'splash'
