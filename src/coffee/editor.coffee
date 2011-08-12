class @Editor

    constructor: ( @id, options ) ->
        @tabstop  = 8
        @linewrap = 80
        this[k] = v for own k, v of options
        @font = @loadFont()
        @canvas = document.getElementById(@id)
        nullCursor = "url('data:image/cur;base64,AAACAAEAICAAAAAAAAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8%3D'), auto"
        $('#cursor').css( 'cursor', nullCursor )
        $('#' + @id).css( 'cursor', nullCursor )
        @width = @canvas.clientWidth if !@width?
        @height = @canvas.clientHeight if !@height?
        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height
        @cursor = new Cursor 8, 16, @
        @grid = []
        @palette = [
            [ 0, 0, 0 ],
            [ 170, 0, 0 ],
            [ 0, 170, 0 ],
            [ 170, 85, 0 ],
            [ 0, 0, 170 ],
            [ 170, 0, 170 ],
            [ 0, 170, 170 ],
            [ 170, 170, 170 ],
            [ 85, 85, 85 ],
            [ 255, 85, 85 ],
            [ 85, 255, 85 ],
            [ 255, 255, 85 ],
            [ 85, 85, 255 ],
            [ 255, 85, 255 ],
            [ 85, 255, 255 ],
            [ 255, 255, 255 ]
        ]
        @attr = 7
        @ctx = @canvas.getContext '2d' if @canvas.getContext
        setInterval( () =>
            @draw()
        , 10 )
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
              f11: 122
              f12: 123

            console.log "keydown: " + e.which
            if (!e.shiftKey && !e.ctrlKey && !e.altKey)
                switch e.which
                  when key.left
                    @cursor.moveLeft()
                  when key.right
                    @cursor.moveRight()
                  when key.down
                    if @cursor.y < (@height - @cursor.height) / @cursor.height
                      @cursor.y++
                      @cursor.draw()
                  when key.up
                    if @cursor.y > 0
                      @cursor.y--
                      @cursor.draw()
                  else

        $("body").bind "keypress", (e) =>            
            char = String.fromCharCode(e.which)
            console.log "keypress: " + e.which + "/" + char
            pattern = ///
                [\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>/\?`~-]
            ///
            if char.match(pattern)
                @grid[@cursor.y] = [] if !@grid[@cursor.y]
                @grid[@cursor.y][@cursor.x] = { char: char, attr: @attr }
                @cursor.moveRight()

        $('#' + @id).mousemove ( e ) =>
            @cursor.x = Math.floor( e.pageX / @cursor.width )
            @cursor.y = Math.floor( e.pageY / @cursor.height )
            @cursor.draw()

        @drawPalette('fg')
        @drawPalette('bg')

    drawPalette: (type) ->
        if type == 'fg' then palette = @palette else palette = @palette[0..7]
        container = $('<div class=palette>');
        for p in palette
            block = $('<span>')
            block.css "background-color", @toRgbaString(p)
            container.append(block)
        $(@canvas.parentElement).append(container);

    loadUrl: ( url ) ->
        req = new XMLHttpRequest
        req.open 'GET', url, false
        req.overrideMimeType 'text/plain; charset=x-user-defined'
        req.send null
        content = if req.status is 200 or req.status is 0 then req.responseText else ''
        return content

    loadFont: ->
        data = @loadUrl '8x16.dat'
        chars = []
        for i in [ 0 .. 255 ]
            chr = []
            for j in [ 0 .. 15 ]
                chr.push data.charCodeAt( i * 16 + j ) & 255
            chars.push chr 
        return chars

    draw: ->
        @ctx.fillStyle = "#000000"
        @ctx.fillRect 0, 0, @canvas.width, @canvas.height
        for y in [0..@grid.length]
            continue if !@grid[y]?
            for x in [0..@grid[y].length]
                continue if !@grid[y][x]?
                px = x * @cursor.width
                py = y * @cursor.height

                @ctx.fillStyle = @toRgbaString( @palette[ ( @grid[y][x].attr & 240 ) >> 4 ] )
                @ctx.fillRect px, py, 8, 16

                @ctx.fillStyle = @toRgbaString( @palette[ @grid[y][x].attr & 15 ] )
                chr = @font[ @grid[y][x].char.charCodeAt( 0 ) & 255 ]
                for i in [ 0 .. 15 ]
                    line = chr[ i ]
                    for j in [ 0 .. 7 ]
                        if line & ( 1 << 7 - j )
                            @ctx.fillRect px + j, py + i, 1, 1

        @ctx.fill()
        return true

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)';

    class Cursor

        constructor: (@width, @height, @editor) ->
            @x = 0
            @y = 0
            @dom = $("#cursor")
            @dom.width @width
            @dom.height @height
            @draw()
            @color = 7
        draw: ->
            @dom.css( 'top', @y * @height )
            @dom.css( 'left', @x * @width )
        moveRight: ->
            if @x < @editor.width/@width - 1
                @x++
            else if @y < @editor.height/@height - 1
                @x =0;
                @y++
            @draw()
            return true                
        moveLeft: ->
            if @x > 0
                @x--
            else if @y > 0
                @y--
                @x = @editor.width/@width - 1
            @draw()
            return true

$(document).ready ->
    new Editor "editor", {width: 640, height: 400}

