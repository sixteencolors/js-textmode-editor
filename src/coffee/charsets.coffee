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
                char.attr 'width', editor.font.width
                char.attr 'height', editor.font.height

                ctx = char[ 0 ].getContext '2d'
                ctx.fillStyle = '#fff'
                for y in [ 0 .. editor.font.height - 1 ]
                    line = editor.font.chars[ c ][ y ]
                    for x in [ 0 .. editor.font.width - 1 ]
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

