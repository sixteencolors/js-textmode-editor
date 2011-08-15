class @Editor

    constructor: ( options ) ->
        @tabstop  = 8
        @linewrap = 80
        @id = 'canvas'
        this[k] = v for own k, v of options
        @font = @loadFont()
        @canvas = document.getElementById(@id)
        # nullCursor = "url('data:image/cur;base64,AAACAAEAICAAAAAAAAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8%3D'), auto"
        # $('#cursor').css( 'cursor', nullCursor )
        # $('#' + @id).css( 'cursor', nullCursor )
        @width = @canvas.clientWidth
        @height = @canvas.clientHeight
        @canvas.setAttribute 'width', @width
        @canvas.setAttribute 'height', @height
        @cursor = new Cursor 8, 16, @
        @locked = false
        @grid = []
        @chars = [
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
        @charset = 5
        @char = 0
        @fg = 7
        @bg = 0

        # WORK IN PROGRESS
        @pal = new Palette
        @pal.draw @
        @sets = new CharacterSets @chars
        @sets.draw @
        # WORK IN PROGRESS
        
        @ctx = @canvas.getContext '2d' if @canvas.getContext
        setInterval( () =>
            @draw()
        , 1 )
        $('#clear').click =>
            @grid = []
            return false
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
              backspace: 8
              delete: 46
              end: 35
              home: 36
              enter: 13

            console.log "keydown: " + e.which
            mod = e.shiftKey || e.altKey || e.ctrlKey
            switch e.which
                when key.left
                    if (!mod)
                        @cursor.moveLeft()
                    else if e.ctrlKey || e.shiftKey #for now, mac os x has command for ctrl-right
                        if @bg < 7 then @bg++ else @bg = 0
                when key.right
                    if (!mod)
                        @cursor.moveRight()
                    else if e.ctrlKey || e.shiftKey
                        if @bg > 0 then @bg-- else @bg = 7
                when key.down
                    if (!mod)
                        if @cursor.y < (@height - @cursor.height) / @cursor.height
                          @cursor.y++
                    else if (e.ctrlKey)
                        if @fg < 15 then @fg++ else @fg = 0
                when key.up
                    if (!mod)
                        if @cursor.y > 0
                          @cursor.y--
                          @cursor.draw()
                    else if e.ctrlKey
                        if @fg > 0 then @fg-- else @fg = 15
                when key.backspace
                    @cursor.moveLeft()
                    @putChar(32)
                    @cursor.moveLeft()
                    return false;
                when key.delete
                    oldrow = @grid[@cursor.y]
                    @grid[@cursor.y] = oldrow[0..@cursor.x-1].concat(oldrow[@cursor.x+1..oldrow.length-1])
                when key.end
                    @cursor.x = @width / @cursor.width - 1
                when key.home
                    @cursor.x = 0
                when key.enter
                    @cursor.x = 0
                    @cursor.y++
                else 
                    if e.which >= 112 && e.which <= 123
                        if !e.altKey && !e.shiftKey && !e.ctrlKey
                            @putChar(@chars[@charset][e.which-112])
                        else if e.altKey
                            @sets.swap(@charset, @charset = e.which - 112)
                        return false
            @cursor.draw()

        $("body").bind "keypress", (e) =>            
            char = String.fromCharCode(e.which)
            console.log "keypress: " + e.which + "/" + char
            pattern = ///
                [\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>/\?`~-]
            ///
            if char.match(pattern) && e.which <= 255 && !e.ctrlKey
                @putChar(char.charCodeAt( 0 ) & 255);                    

        $('#' + @id).mousemove ( e ) =>
            if @cursor.mousedown
                @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left )  / @cursor.width )
                @cursor.y = Math.floor( e.pageY / @cursor.height )
                @putChar(@chars[@charset][@char]) if @locked
                return true

        $('#' + @id).mousedown ( e ) => # Pablo only moves the cursor on click, this feels a little better when used -- may need to re-evaluate for touch usage
            @cursor.mousedown = true
            @cursor.x = Math.floor( ( e.pageX - $('#' + @id).offset().left )  / @cursor.width )
            @cursor.y = Math.floor( e.pageY / @cursor.height )
            @putChar(@chars[@charset][@char]) if @locked
            @cursor.draw()
            return true

        $('#' + @id).mouseup ( e ) =>
            @cursor.mousedown = false
            @cursor.draw()

    putChar: (charCode) ->
        @grid[@cursor.y] = [] if !@grid[@cursor.y]
        @grid[@cursor.y][@cursor.x] = { char: charCode, attr: ( @bg << 4 ) | @fg }
        @cursor.moveRight()

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
        for y in [0..@grid.length - 1]
            continue if !@grid[y]?
            for x in [0..@grid[y].length - 1]
                continue if !@grid[y][x]?
                px = x * @cursor.width
                py = y * @cursor.height

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
        return true

    class Cursor

        constructor: (@width, @height, @editor) ->
            @x = 0
            @y = 0
            @dom = $("#cursor")
            @dom.width @width
            @dom.height @height
            @draw()
            @mousedown = false
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
        
class CharacterSets 
    constructor: (@chars) ->
        @width = 8
        @height = 16
        @element = $('#charsets')

    draw: ( editor )->
        for row in [0..@chars.length - 1]
            charSet = $('<div class=set id=set' + row + '>')
            for c in [0..@chars[row].length - 1]
                chr = editor.font[ @chars[row][ c ] ]
                char = document.createElement('canvas')
                char.setAttribute 'width', @width
                char.setAttribute 'height', @height
                ctx = char.getContext '2d' if char.getContext
                ctx.fillStyle =  '#ffffff'
                for i in [ 0 .. 15 ]
                    line = chr[ i ]
                    for j in [ 0 .. 7 ]
                        if line & ( 1 << 7 - j )
                            ctx.fillRect j, i, 1, 1
                ctx.fill()
                charSet.append($('<span class=char id=set' + row + 'char' + c + '>').append(char))
                @element.append( charSet )
                charContainer = $('#set' + row + 'char' + c)
                charContainer.addClass('selected') if editor.charset == row && editor.char == c
                charContainer.click ( e ) =>
                    pattern = ///
                        set(\d+)char(\d+)
                    ///
                    matches = e.currentTarget.id.match(pattern)
                    $('#set' + editor.charset + 'char' + editor.char).removeClass('selected')
                    $('#set' + (editor.charset = matches[1] )+ 'char' + (editor.char = matches[2])).addClass('selected')

        $('#set' + editor.charset).fadeIn()
        @element.parent().append('<div id=charnavigator><span id=prev></span><span id=next></span></span></div>')
        @element.parent().append('<div id=locker>Lock</div>')
        $('#next').click ( e ) =>
            @swap(editor.charset, editor.charset = if editor.charset < @chars.length - 1 then editor.charset = editor.charset + 1 else editor.charset = 0)
        $('#prev').click ( e ) =>
            @swap(editor.charset, editor.charset = if editor.charset > 0 then editor.charset = editor.charset - 1 else editor.charset = @chars.length - 1)
        $('#locker').click ( e ) =>
            editor.locked = !editor.locked
            $('#locker').css 'color', if editor.locked then '#fff' else '#000'
        return true
    swap: (oldset, newset) ->
        duration = 150
        $('#set' + oldset).fadeOut(duration)
        $('#set' + newset).delay(duration+duration*.1).fadeIn()

class Palette

    constructor: ->
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
        @element = $('#palette')

    draw: ( editor ) ->
    @element.append( fg ).append( bg )
        for i in @colors[0..@colors/2]
            block = $('<div>')
            block.css 'background-color', @toRgbaString( i )
            block.css 'height', '32px'
            block.css 'width', '32px'
            @element.append( block )

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)';

$(document).ready ->
    $('#close').click ->
        $('#splash').hide()
        return false

    new Editor

