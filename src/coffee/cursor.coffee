class Cursor

    constructor: ( options ) ->
        @x = 0
        @y = 0
        @mousedown = false
        @mode = 'ovr'
        @selector = $( '#cursor' )
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
        width = @editor.font.width
        height = @editor.font.height
        @selector.css 'width', width
        @selector.css 'height', height
        @selector.css 'left', @x * width
        @selector.css 'top', @y * height

    moveRight: ->
        if @x < @editor.width / @editor.font.width - 1
            @x++
        else if @y < @editor.height / @editor.font.height - 1
            @x =0
            @y++
        @draw()

    moveLeft: ->
        if @x > 0
            @x--
        else if @y > 0
            @y--
            @x = @editor.width / @editor.font.width - 1
        @draw()

