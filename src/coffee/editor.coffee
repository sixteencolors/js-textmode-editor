class Editor

    constructor: ( @id, options ) ->
        @tabstop  = 8
        @linewrap = 80
        this[k] = v for own k, v of options
        @canvas = $("##{ @id }")
        @canvas.style.cursor = "url('data:image/cur;base64,AAACAAEAICAAAAAAAAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8%3D'), auto"
        @canvas.setAttribute 'width', this.width
        @canvas.setAttribute 'height', this.height
        @width = @canvas.clientWidth
        @height = @canvas.clientHeight
        @cursor = new Cursor 8, 16
        @grid = []
        @grid[x].push new Block " ", 0 for x in [0..@width/@cursor.width] for y in [0..@height/@cursor.height]
        @ctx = @canvas.getContext '2d' if @canvas.getContext
        setInterval 'editor.draw()', 10
        $("body").bind "keydown", (e) ->
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
        switch e.which
          when key.left
            editor.cursor.moveLeft()
          when key.right
            editor.cursor.moveRight()
          when key.down
            if editor.cursor.y < (editor.height - editor.cursor.height) / editor.cursor.height
              editor.cursor.y++
              editor.cursor.draw()
          when key.up
            if editor.cursor.y > 0
              editor.cursor.y--
              editor.cursor.draw()
          else

        $("body").bind "keypress", (e) ->
        letter = String.fromCharCode(e.which)
        console.log "keypress: " + e.which + "/" + letter
        block = new Block(letter, 0)
        editor.grid[editor.cursor.x][editor.cursor.y] = block
        editor.cursor.moveRight()

    draw: ->
        @ctx.fillStyle = "#000000"
        @ctx.fillRect 0, 0, @canvas.width, @canvas.height
        @ctx.fillStyle = "#ababab"
        for x in @grid 
            do (x) ->
                for y in @grid[x] 
                    do (y) -> 
                        @ctx.fillRect x * @cursor.width, y*@cursor.height, @cursor.width, @cursor.height 

    class Block

        constructor: (@char, @attr) ->

    class Cursor

        constructor: (@wdith, @height) ->

    