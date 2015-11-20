$ = jquery = require './lib/jquery'

project-name = 'fish-headings'

{ log, ierror, is-num, is-int, is-a-num, round } = util = require './util'

#{ each } = prelude-ls = require 'prelude-ls'

module.exports =
    init: init
    collapse: collapse

$main = void
items = []
num-items = -1
$container = void

container-width = -1
collapsed-height = -1

span-widths = []
longest-width = -1
span-height-large = void

function init $_container, vals, opts = {}
    $container := $_container

    container-width := $container.width()

    #list-icon-class = opts.list-icon-class ? []

    num-items := vals.length

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
        items.push $item

    $container.append $main

    collapsed-height := if opts.collapsed-height? then that else $container.height()

function collapse n
    tops = []
    lefts = []
    items.for-each ($v) ->
        offset = $v.position()
        tops.push offset.top
        lefts.push offset.left

        span = $v.find 'span' .1
        $span = $ span
        width = $span.width()
        longest-width := Math.max width, longest-width
        span-height-large := $span.height() unless span-height-large?
        span-widths.push width
        log 'pushing width' $span.width()
        log 'pushing left' offset.left
    items.for-each ($v) ->
        top = tops.shift()
        left = lefts.shift()
        $v
            .css 'position' 'absolute'
            .css 'top' top
            .css 'left' left

    set-timeout do
        -> select n
        0

function select n
    width-enabled = -1
    items.for-each ($v, i) ->
        $v
            .remove-class 'disabled'
            .remove-class 'enabled'
        if i == n
            $v.add-class 'enabled'
            #width-enabled := $v.width()
        else
            $v.add-class 'disabled'

    log 'span-height-large' span-height-large

    j = -1
    items.for-each ($v, i) ->
        if i == n
            $v.css 'left' 0
            top = (collapsed-height / 2) - (span-height-large / 2)
            $v.css 'top' top
        else
            j++
            #$v.css 'left' longest-width + 15 # XX
            $v
                .css 'left' ''
                #.css 'right' 10
            span-height-small = 10 # XX
            top = (collapsed-height - span-height-small) / (num-items - 2) * j
            $v.css 'top' top

    $container.height collapsed-height

function expand
    log 'no op expand'
