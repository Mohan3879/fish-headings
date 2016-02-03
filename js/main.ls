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
    collision-gutter: 20
    max-transition-time-ms: 100
    width-threshold-hide-disabled: 600

our =
    items: []

    $main: void
    $window: void

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

    is-below-width-threshold: void

function init $_container, vals, opts = {}
    our.$container = $_container
    our.$window = $ window
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
        #check-collisions()
        return

    absolutise()

    set-timeout do
        -> collapse-do n
        0

# -- private
function collapse-do n
    our.selected = n

    our.$container.add-class config.class.container-collapsed

    # --- remove all classes, add enabled to the enabled and disabled to the
    # rest.
    our.items.for-each ($v, i) ->
        $v
            .remove-class config.class.heading-disabled
            .remove-class config.class.heading-enabled
        if i == n
            $v.add-class config.class.heading-enabled
        else
            $v.add-class config.class.heading-disabled

    cnt-disabled = -1

    # --- no longer using.
    modified-css = 0

    our.items.for-each ($v, i) ->
        modify-css-v = modify-css.bind null $v
        # --- undo the 'left' which we applied earlier so that css classes
        # work.
        modified-css := modified-css + $v.css 'left' ''

        # --- enabled.
        if i == n
            top = (divide our.collapsed-height-inner, 2) - (our.span-height-large / 2)
            modified-css := modified-css + modify-css-v 'top' top

            $v.show()

        # --- disabled.
        else
            cnt-disabled := cnt-disabled + 1

            if our.is-below-width-threshold then $v.hide()
            else $v.show()

            span-height-small = 10 # XX
            top = do ->
                height = subtract our.collapsed-height-inner, span-height-small
                delta = divide height, (our.num-items - 2)
                multiply delta, cnt-disabled
            modified-css := modified-css + modify-css-v 'top' top

    # --- it's possible that no css changed on any item during this call, so
    # transitionend won't fire and check-collisions won't get called.
    #
    # it's also possible to have quirks where the calculations happen during
    # a transition.
    #
    # so call it manually after all transitions are presumed to be finished.

    #set-timeout do
    #    check-collisions
    #    config.max-transition-time-ms * 1.1

function expand
    return unless our.selected?
    our.$container
        ..remove-class config.class.container-collapsed
        ..css 'min-height' ''
        ..css 'max-height' ''

    restore()
    our.selected = void

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
        #check-collisions()

function calculate
    our.padding-top = make-absolute our.opts.padding-top ? 0, 'vertical'
    our.padding-bottom = make-absolute our.opts.padding-bottom ? 0, 'vertical'

    window-width = our.$window.width()
    our.is-below-width-threshold = window-width < config.width-threshold-hide-disabled

    our.$container
        .css 'padding-top' our.padding-top
        .css 'padding-bottom' our.padding-bottom

    our.collapsed-height-inner = if our.opts.collapsed-height-inner then
        make-absolute that, 'vertical'
    else
        void

# --- inject the contents and calculate 'collapsed-height'; should happen
# after each window resize as well.
#
# triggers /collapsed-height.

function inject
    our.$container.append our.$main

    our.expanded-height = our.$container.outer-height()

    collapsed-inner = our.collapsed-height-inner ? our.expanded-height
    our.collapsed-height = add collapsed-inner, our.padding-top, our.padding-bottom

    our.$main.trigger '/collapsed-height'

# --- put everything in its canonical position (left) so we can calculate
# things.
#
# this can cause a flicker where the whole div gets too high for a moment, so
# set a max-height.

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

    our.$container.css 'min-height' our.collapsed-height
    our.$container.css 'max-height' our.collapsed-height

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

# --- @private
#
# when collapsed, check if the right column is too close to the left column
# (this will happen e.g. on mobile).
#
# if so, make the right column invisible -- they will have to make do with
# only the main headings.

function check-collisions

    return

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

# --- applies css and returns true if it's actually a modification.
#
# does no conversion of types.

function modify-css $target, prop, value
    cur-val = $target.css prop
    $target.css prop, value

    cur-val != value
