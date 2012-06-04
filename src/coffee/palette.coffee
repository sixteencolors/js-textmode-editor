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

        $( '#colors' ).children().empty()
        $( '#colors' ).append '<ul class=first></ul>', '<ul></ul>'

        for i in [ 0 .. @colors.length - 1 ]
            block = $( '<li>' )
            block.data 'color', i
            block.css 'background', @toRgbaString @colors[ i ]
            block.click ( e ) =>
                @[ indicators.filter( '.selected' ).attr 'id' ] = $( e.target ).data 'color'
                @draw()
            $( '#colors ul:nth-child(' + ( 1 + Math.round( i / ( @colors.length - 1 ) ) ) + ')' ).append block
        @draw()

    draw: ->
        $( '#fg' ).css 'background-color', @toRgbaString @colors[ @fg ]
        $( '#fg' ).css 'color', @toRgbaString @colors[ if @fg > 8 then 0 else 15 ]
        $( '#bg' ).css 'background-color', @toRgbaString @colors[ @bg ]
        $( '#bg' ).css 'color', @toRgbaString @colors[ if @bg > 8 then 0 else 15 ]

    toRgbaString: ( color ) ->
        return 'rgba(' + color.join( ',' ) + ',1)'

