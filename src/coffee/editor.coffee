class @Editor

    constructor: ( options ) ->
        @tabstop  = 8
        @id = 'canvas'
        @vga_id = 'vga'
        @vga_scale = '.25'
        this[k] = v for own k, v of options

    init: ->
        @font = @loadFont()
        @canvas = document.getElementById(@id)
        @width = @canvas.clientWidth - @canvas.clientWidth % 8
        @height = @canvas.clientHeight - @canvas.clientHeight % 16
        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height
        @vga_canvas = document.getElementById(@vga_id)
        @vga_canvas.setAttribute 'width', @width * @vga_scale
        @vga_canvas.setAttribute 'height', @height
        @grid = []

        @cursor = new Cursor
        @cursor.init @
        @pal = new Palette
        @pal.init @
        @sets = new CharacterSets
        @sets.init @
        
        @ctx = @canvas.getContext '2d' if @canvas.getContext
        @vga_ctx = @vga_canvas.getContext '2d' if @vga_canvas.getContext
        setInterval( () =>
            @draw()
        , 50 )

        $('#clear').click =>
            answer = confirm('Clear canvas?');
            if (answer)
                @grid = [];

        $('#save').click =>
            window.open(@canvas.toDataURL("image/png"), 'ansiSave')

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
              insert: 45

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
                    @cursor.x = @width / 8 - 1
                when key.home
                    @cursor.x = 0
                when key.enter
                    @cursor.x = 0
                    @cursor.y++
                when key.insert
                    @cursor.change_mode()
                else 
                    if e.which >= 112 && e.which <= 121
                        if !e.altKey && !e.shiftKey && !e.ctrlKey
                            @putChar(@sets.sets[ @sets.set ][e.which-112])
                        else if e.altKey
                            @sets.set = e.which - 112
                            @sets.fadeSet()
                        return false
            @pal.draw()
            @cursor.draw()

        $("body").bind "keypress", (e) =>            
            char = String.fromCharCode(e.which)
            pattern = ///
                [\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>/\?`~\-\s]
            ///
            if char.match(pattern) && e.which <= 255 && !e.ctrlKey && e.which != 13
                @putChar(char.charCodeAt( 0 ) & 255);                    

        $('#' + @id).mousemove ( e ) =>
            if @cursor.mousedown
                @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left )  / 8 )
                @cursor.y = Math.floor( e.pageY / 16 )
                @putChar(@sets.char) if @sets.locked
                return true

        $('#' + @id).mousedown ( e ) => # Pablo only moves the cursor on click, this feels a little better when used -- may need to re-evaluate for touch usage
            @cursor.mousedown = true
            @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left )  / 8 )
            @cursor.y = Math.floor( e.pageY / 16 )
            @putChar(@sets.char) if @sets.locked
            @cursor.draw()
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

    putTouchChar: ( touch ) ->
        node = touch.target
        @cursor.x = Math.floor( ( touch.pageX - $('#' + @id).offset().left )  / 8 )
        @cursor.y = Math.floor( touch.pageY / 16 )
        @putChar(@sets.char) if @sets.locked
        return true

    putChar: (charCode) ->
        @grid[@cursor.y] = [] if !@grid[@cursor.y]
        if @cursor.mode == 'ins'
            # NOTE: this will push chars off the right-side of the canvas
            # but will still have an entry in the grid
            row = @grid[@cursor.y][@cursor.x..]
            @grid[@cursor.y][@cursor.x + 1..] = row
        @grid[@cursor.y][@cursor.x] = { char: charCode, attr: ( @pal.bg << 4 ) | @pal.fg }
        @cursor.moveRight()

    loadUrl: ( url ) ->
        req = new XMLHttpRequest
        req.open 'GET', url, false
        if req.overrideMimeType
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
        for y in [0..@grid.length - 1]
            continue if !@grid[y]?
            for x in [0..@grid[y].length - 1]
                continue if !@grid[y][x]?
                px = x * 8
                py = y * 16

                @ctx.fillStyle = @pal.toRgbaString( @pal.colors[ ( @grid[y][x].attr & 240 ) >> 4 ] ) #bg
                @ctx.fillRect px, py, 8, 16

                @ctx.fillStyle = @pal.toRgbaString( @pal.colors[ @grid[y][x].attr & 15 ] ) #fg
                chr = @font[ @grid[y][x].char ]
                for i in [ 0 .. 15 ]
                    line = chr[ i ]
                    for j in [ 0 .. 7 ]
                        if line & ( 1 << 7 - j )
                            @ctx.fillRect px + j, py + i, 1, 1

        @ctx.fill()

        $( '#cursorpos' ).text '(' + (@cursor.x + 1) + ', ' + (@cursor.y + 1) + ')'

        @vga_ctx.drawImage(@canvas, 0, 0, @canvas.width, @canvas.height, 0, 0, @canvas.width * @vga_scale, @canvas.height * @vga_scale);

class Cursor

    constructor: ( options ) ->
        @x = 0
        @y = 0
        @mousedown = false
        @mode = 'ovr'
        this[k] = v for own k, v of options

    init: ( @editor ) ->
        @draw()

    change_mode: ( mode ) ->
        if mode
            $( '#cursor' ).attr 'class', mode
        else 
            $( '#cursor' ).toggleClass 'ins'

        @mode = $( '#cursor' ).attr( 'class' ) || 'ovr'

    draw: ->
        $( '#cursor' ).css 'left', @x * 8
        $( '#cursor' ).css 'top', @y * 16

    moveRight: ->
        if @x < @editor.width / 8 - 1
            @x++
        else if @y < @editor.height / 16 - 1
            @x =0
            @y++
        @draw()

    moveLeft: ->
        if @x > 0
            @x--
        else if @y > 0
            @y--
            @x = @editor.width / 8 - 1
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
                char.attr 'width', 8
                char.attr 'height', 16

                ctx = char[ 0 ].getContext '2d'
                ctx.fillStyle = '#fff'
                for y in [ 0 .. 15 ]
                    line = editor.font[ c ][ y ]
                    for x in [ 0 .. 7 ]
                        if line & ( 1 << 7 - x )
                            ctx.fillRect x, y, 1, 1

                charwrap = $( '<li>' )
                charwrap.data 'char', c
                charwrap.data 'pos', j
                charwrap.append char
                chars.append charwrap

            set.append chars
            $( '#sets' ).append set

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
            @draw()

        @draw()

    draw: ->
        sets = $( '#sets > li' )
        sets.hide()
        set = sets.filter( ':nth-child(' + ( @set + 1 ) + ')' )
        set.show()
        set.find( 'li' ).removeClass( 'selected' )
        set.find( 'li:nth-child(' + ( @charpos + 1 ) + ')' ).addClass( 'selected' )
        

    fadeSet: ->
        $('#sets > li:visible' ).fadeOut( 'fast', () =>
            $('#sets > li:nth-child(' + ( @set + 1 ) + ')' ).fadeIn( 'fast' )
            @char = @sets[ @set ][ @charpos ]
            @draw()
        )

class Palette

    constructor: ( options ) ->
        @colors = [
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
        @fg = 7
        @bg = 0
        this[k] = v for own k, v of options

    init: ( editor ) ->
        indicators = $( '#fg,#bg' )
        indicators.click ( e ) ->
            if !$( e.target ).hasClass( 'selected' )
                indicators.toggleClass( 'selected' )
        for i in [ 0 .. @colors.length - 1 ]
            block = $( '<li>' )
            block.data 'color', i
            block.css 'background', @toRgbaString @colors[ i ]
            block.click ( e ) =>
                @[ indicators.filter( '.selected' ).attr 'id' ] = $( e.target ).data 'color'
                @draw()
            $( '#colors' ).append block
        @draw()

    draw: ->
        $( '#fg' ).css 'background-color', @toRgbaString @colors[ @fg ]
        $( '#fg' ).css 'color', @toRgbaString @colors[ if @fg > 8 then 0 else 15 ]
        $( '#bg' ).css 'background-color', @toRgbaString @colors[ @bg ]
        $( '#bg' ).css 'color', @toRgbaString @colors[ if @bg > 8 then 0 else 15 ]

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)'

$( document ).ready ->
    $( '#splash' ).slideToggle 'slow'
    $( '#close' ).click ->
        $( '#splash' ).slideToggle 'slow'
        return false

    editor = new Editor
    editor.init()
