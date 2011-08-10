class @ANSI

    constructor: ( ) ->
        @font     = @loadFont()
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
        @tabstop  = 8
        @linewrap = 80

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)';

    loadUrl: ( url ) ->
        req = new XMLHttpRequest
        req.open 'GET', url, false
        req.overrideMimeType 'text/plain; charset=x-user-defined'
        req.send null
        content = if req.status is 200 or req.status is 0 then req.responseText else ''
        return content

    parseUrl: ( url ) ->
        @parse @loadUrl url

    loadFont: ->
        data = @loadUrl 'js/8x16.dat'
        chars = []
        for i in [ 0 .. 255 ]
            chr = []
            for j in [ 0 .. 15 ]
                chr.push data.charCodeAt( i * 16 + j ) & 255
            chars.push chr 
        return chars

    getWidth: ->
        max = 0
        for y in [ 0 .. @screen.length - 1 ]
            max = @screen[ y ].length if @screen[ y ]? && @screen[ y ].length > max
        return max

    getHeight: ->
        return @screen.length

    renderCanvas: ( canvasElem ) ->
        w = @getWidth() * 8
        h = @getHeight() * 16

        canvas = document.createElement 'canvas'
        canvas.setAttribute 'width', w
        canvas.setAttribute 'height', h
        ctx = canvas.getContext '2d'

        for cy in [ 0 .. @screen.length - 1 ]
            continue if !@screen[ cy ]?
            for cx in [ 0 .. @screen[ cy ].length - 1 ]
                pixel = @screen[ cy ][ cx ]
                continue if !pixel?
                fg = pixel.attr & 15
                bg = ( pixel.attr & 240 ) >> 4

                px = cx * 8
                py = cy * 16

                ctx.fillStyle = @toRgbaString( @palette[ bg ] )
                ctx.fillRect px, py, 8, 16

                ctx.fillStyle = @toRgbaString( @palette[ fg ] )
                chr = @font[ pixel.ch.charCodeAt( 0 ) & 255 ]
                for i in [ 0 .. 15 ]
                    line = chr[ i ]
                    for j in [ 0 .. 7 ]
                        if line & ( 1 << 7 - j )
                            ctx.fillRect px + j, py + i, 1, 1

        canvasElem.setAttribute 'width', w
        canvasElem.setAttribute 'height', h
        ctx = canvasElem.getContext '2d'
        ctx.drawImage canvas, 0, 0

    parse: ( content ) ->
        @screen = []
        @state = 0
        @x = 0
        @y = 0
        @save_x = 0
        @save_y = 0
        @attr = 7
        @argbuf = ''

        content = content.split( '' )
        while ch = content.shift()
            if @state is 0
                switch ch
                    when "\x1a" then @state = 3
                    when "\x1b" then @state = 1
                    when "\n"
                        @x = 0
                        @y++
                    when "\r" then break
                    when "\t"
                        i = ( @x + 1 ) % @tabstop
                        @putpixel ' ' while i-- > 0
                    else
                        @putpixel ch 

            else if @state is 1
                if ch isnt "["
                    @putpixel "\x1b" 
                    @putpixel "[" 
                    @state = 0
                else
                    @state = 2

            else if @state is 2
                if ch.match( '[A-Za-z]' )
                    args = ( parseInt( i ) for i in @argbuf.split ';' )

                    switch ch
                        when "m"
                            for arg in args
                                if arg is 0
                                    @attr = 7
                                else if arg is 1
                                    @attr |= 8
                                else if arg is 5
                                    @attr |= 128
                                else if 30 <= arg <= 37
                                    @attr &= 248
                                    @attr |= ( arg - 30 )
                                else if 40 <= arg <= 47 
                                    @attr &= 143
                                    @attr |= ( arg - 40 ) << 4

                        when "H", "f"
                            @y = ( args[ 0 ] or 1 ) - 1
                            @x = ( args[ 1 ] or 1 ) - 1
                            @y = 0 if @y < 0
                            @x = 0 if @x < 0
                        when "A"
                            @y -= args[ 0 ] or 1
                            @y = 0 if @y < 0
                        when "B"
                            @y += args[ 0 ] or 1
                        when "C"
                            @x += args[ 0 ] or 1
                        when "D"
                            @x -= args[ 0 ] or 1
                            @x = 0 if @x < 0
                        when "E"
                            @y += args[ 0 ] or 1
                            @x = 0
                        when "F"
                            @y -= args[ 0 ] or 1
                            @y = 0 if @y > 0
                            @x = 0
                        when "G"
                            @x = ( args[ 0 ] or 1 ) - 1
                        when "s"
                            @save_x = @x
                            @save_y = @y
                        when "u"
                            @x = @save_x
                            @y = @save_y
                        when "J"
                            if args.length is 0 or args[ 0 ] is 0
                                @screen[ i ] = null for i in [ @y + 1 .. screen.length - 1 ]
                                @screen[ @y ][ i ] = null for i in [ @x .. screen[ @y ].length - 1 ]
                            else if args[ 0 ] is 1
                                @screen[ i ] = null for i in [ 0 .. @y - 1 ]
                                @screen[ @y ][ i ] = null for i in [ 0 .. @x ]
                            else if args[ 0 ] is 2
                                @x = 0
                                @y = 0
                                @screen = []
                        when "K"
                            if args.length is 0 or args[ 0 ] is 0
                                @screen[ @y ][ i ] = null for i in [ @x .. @screen[ @y ].length - 1 ]
                            else if args[ 0 ] is 1
                                @screen[ @y ][ i ] = null for i in [ 0 .. @x ]
                            else if args[ 0 ] is 2
                                @screen[ @y ] = null

                    @argbuf = ''
                    @state = 0

                else
                    @argbuf += ch

            else if @state is 3
                break

            else
                @state = 0


    putpixel: ( ch ) ->
        @screen[ @y ] = [] if !@screen[ @y ]?
        @screen[ @y ][ @x ] = { ch: ch, attr: @attr }

        if ++@x >= @linewrap
            @x = 0
            @y++
