class @Editor

    constructor: ( options ) ->
        @tabstop  = 8
        @linewrap = 80
        this[k] = v for own k, v of options
