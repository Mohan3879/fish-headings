$ = jquery = require './lib/jquery'

project-name = 'fish-headings'

{ log, warn } = util = require './util'

module.exports = {
    init,
    collapse,
    expand,
    collapsed-height,
    selected,
    add-listener,
}

config =
    class:
        heading-enabled: 'enabled'
        heading-disabled: 'disabled'
        container-collapsed: 'collapsed'
    collision-gutter: 100

our =
    items: []

    $main: void

    opts: {}

    # expanded
    tops: []
    lefts: []

    num-items: -1
    selected: void
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

    $ window .on 'resize' ->
        our.$container.empty()
        calculate()
        inject()

        if our.selected?
            # check-collisions will happen after transition event
            collapse our.selected, true

function collapse n, force
    if our.selected == n and not force
        check-collisions()
        return

    absolutise()

    set-timeout do
        -> collapse-do n
        0

# -- private
function collapse-do n
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
            $v.css 'top' top

        our.$container.css 'min-height' our.collapsed-height
    # it's possible that no css changed during this call, so
    # transitionend won't fire and check-collisions won't get called.
    check-collisions()

function expand
    return unless our.selected?
    our.$container.remove-class config.class.container-collapsed
    restore()
    our.selected = void

    #check-collisions()

function collapsed-height
    our.collapsed-height

function selected
    our.selected

function add-listener event, cb
    if event is '/collapsed-height' then
        our.$main.on '/collapsed-height' ->
            cb our.collapsed-height
    else
        return warn "Invalid event" bright-red event

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

    our.items.0.on 'transitionend' ->
        return if our.disable-transitionend
        check-collisions()

function calculate
    our.padding-top = make-absolute our.opts.padding-top ? 0, 'vertical'
    our.padding-bottom = make-absolute our.opts.padding-bottom ? 0, 'vertical'

    our.$container
        .css 'padding-top' our.padding-top
        .css 'padding-bottom' our.padding-bottom

    our.collapsed-height-inner = if our.opts.collapsed-height-inner then
        make-absolute that, 'vertical'
    else
        void

function inject
    our.$container.append our.$main

    our.expanded-height = our.$container.outer-height()

    collapsed-inner = our.collapsed-height-inner ? our.expanded-height
    our.collapsed-height = add collapsed-inner, our.padding-top, our.padding-bottom

    our.$main.trigger '/collapsed-height'

function absolutise
    our.items.for-each ($v, i) ->
        $v.css 'position' 'static'
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

    our.$container.css 'min-height' our.expanded-height
    #our.$container.css 'height' our.expanded-height

    our.tops = tops
    our.lefts = lefts

function restore
    our.items.for-each ($v, i) ->
        $v
            .css 'position' 'static'
            .remove-class config.class.heading-disabled
            .add-class config.class.heading-enabled

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
        i .= replace // % $ // ''
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
    return val unless m

    $the-reference = $ window
    the-reference-val = if direction == 'horizontal' then $the-reference.width() else $the-reference.height()
    m.1 * the-reference-val / 100

function check-collisions
    left-stuff-right-edge = -1
    right-stuff-left-edge = -1
    our.items.for-each ($v, i) ->
        $v.show()
    our.items.for-each ($v, i) ->
        if $v.has-class config.class.heading-enabled
            left-stuff-right-edge := $v.offset().left + $v.width()
        else if $v.has-class config.class.heading-disabled
            right-stuff-left-edge := $v.offset().left
        return if right-stuff-left-edge? and left-stuff-right-edge?

    if right-stuff-left-edge <= left-stuff-right-edge + config.collision-gutter
        the-class = '.' + config.class.heading-disabled
        $find = our.$container.find the-class
            .hide()
    # avoid strange javascript syntax error
    1


