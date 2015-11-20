$ = jquery = require './lib/jquery'

project-name = 'fish-headings'

{ log, warn } = util = require './util'

module.exports =
    init: init
    collapse: collapse
    expand: expand

config =
    class:
        heading-enabled: 'enabled'
        heading-disabled: 'disabled'
        container-collapsed: 'collapsed'

our =
    items: []

    $main: void

    opts: {}

    # expanded
    tops: []
    lefts: []

    num-items: -1
    selected: -1
    $container: void
    container-width: -1
    expanded-height: -1
    collapsed-height-inner: -1
    collapsed-height: -1
    longest-width: -1
    flush-left: void

    padding-top: -1
    padding-bottom: -1

function init $_container, vals, opts = {}
    our.$container = $_container
    init-main vals, opts
    calculate()
    inject()
    absolutise()

    # take out XX
    log 'winning'
    $ window .on 'resize' ->
        log 'resizing'
        our.$container.empty()
        calculate()
        inject()

        if our.selected != -1
            collapse our.selected

function collapse n

    our.selected = n

    our.$container.add-class config.class.container-collapsed

    our.items.for-each ($v, i) ->
        $v
            .remove-class config.class.heading-disabled
            .remove-class config.class.heading-enabled
        if i == n
            $v.add-class config.class.heading-enabled
        else
            $v.add-class config.class.heading-disabled

    j = -1
    our.items.for-each ($v, i) ->
        if i == n
            $v.css 'left' 0
            top = (divide our.collapsed-height-inner, 2) - (our.span-height-large / 2)
            log 'topping enabled' top
            $v.css 'top' top
        else
            j++
            if our.flush-left
                $v.css 'left' our.longest-width + 15 # XX
            else
                $v.css 'left' ''
            span-height-small = 10 # XX
            top = do ->
                height = subtract our.collapsed-height-inner, span-height-small
                delta = divide height, (our.num-items - 2)
                multiply delta, j
            log 'topping disabled' top
            $v.css 'top' top

    log '1min-height' our.collapsed-height
    our.$container.css 'min-height' our.collapsed-height

function expand
    our.$container.remove-class config.class.container-collapsed
    restore()

# -- private

function init-main vals, _opts = {}

    our.num-items = vals.length
    our.opts = _opts
    our.flush-left = _opts.flush-left ? false

    $main = $ '<div>'
        ..attr 'id' project-name

    vals.for-each (v, i) ->
        if typeof! v is 'Object'
            { text, href, list-icon-class } = v
            list-icon-class ?= []
        else
            text = v
            list-icon-class = []
        $item = $ '<div>'
            ..attr 'id' i
        $span-icon = $ '<span>'
        list-icon-class.for-each ->
            $span-icon.add-class it
        if href
            $span-contents = $ '<a>'
                ..attr 'href' href
                ..html text
            $span-text = $ '<span>'
                ..append $span-contents
        else
            $span-text = $ '<span>'
                ..html text
        $main.append $item
        $item.append $span-icon
        $item.append $span-text
        our.items.push $item

    our.$main = $main

function calculate
    our.padding-top = make-absolute our.opts.padding-top ? 0, 'vertical'
    our.padding-bottom = make-absolute our.opts.padding-bottom ? 0, 'vertical'

    our.$container
        .css 'padding-top' our.padding-top
        .css 'padding-bottom' our.padding-bottom

    our.collapsed-height-inner = make-absolute our.opts.collapsed-height-inner, 'vertical'


function inject
    our.$container.append our.$main

    our.expanded-height = our.$container.outer-height()
    log 'expanded-height' our.expanded-height
    #our.collapsed-height-inner = opts.collapsed-height-inner ? our.expanded-height

    # move to init
    our.collapsed-height = add our.collapsed-height-inner, our.padding-top, our.padding-bottom

function absolutise
    tops = []
    lefts = []
    our.items.for-each ($v, i) ->
        offset = $v.position()
        tops.push offset.top
        lefts.push offset.left

        span = $v.find 'span' .1
        $span = $ span
        width = $span.width()
        our.longest-width = Math.max width, our.longest-width
        our.span-height-large = $span.height() if i == 0
    our.items.for-each ($v, i) ->
        top = tops[i]
        left = lefts[i]
        $v
            .css 'position' 'absolute'
            .css 'top' top
            .css 'left' left

    log '2min-height' our.expanded-height
    our.$container.css 'min-height' our.expanded-height
    #our.$container.css 'height' our.expanded-height

    our.tops = tops
    our.lefts = lefts

function restore
    our.items.for-each ($v, i) ->
        top = our.tops[i]
        left = our.lefts[i]
        $v
            .css 'top' top
            .css 'left' left
            .remove-class config.class.heading-disabled
            .add-class config.class.heading-enabled

    log '3min-height' our.expanded-height
    our.$container.css 'min-height' our.expanded-height

function op the-op, values
    percent-mode = false
    result = void
    reduce = (a, b) ->
        if the-op == 'add'
            return a + b
        if the-op == 'subtract'
            return a - b
        if the-op == 'multiply'
            return a * b
        if the-op == 'divide'
            return a / b
    k = -1
    j = ''
    for i in values
        k++
        i += ''
        j = i
        log 'before' i
        i .= replace // % $ // ''
        log 'after' i
        # percent mode
        if i != j
            #if percent-mode == false return warn "add: can't mix percent and pixels"
            percent-mode = true
        # pixel mode
        #else
            #if percent-mode == true return warn "add: can't mix percent and pixels"
            #percent-mode = false
        if k == 0
            result = +i
        else
            result = reduce result, +i
    result += '%' if percent-mode

    result

# document, check ... XX
function add
    op 'add' [.. for &]
function subtract
    op 'subtract' [.. for &]
function divide
    op 'divide' [.. for &]
function multiply
    op 'multiply' [.. for &]

# direction is 'vertical' or 'horizontal'
function make-absolute val, direction
    m = val == // ^ (.+) % $ //
    log 'make-absolute:' val unless m
    return val unless m

    $the-reference = $ window
    the-reference-val = if direction == 'horizontal' then $the-reference.width() else $the-reference.height()
    log 'make-absolute:' m.1 / 100 * the-reference-val
    m.1 * the-reference-val / 100


