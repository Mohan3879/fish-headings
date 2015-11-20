$ = jquery = require 'jquery'

project-name = 'fish-headings'

{ log, ierror, is-num, is-int, is-a-num, round } = util = require './util'

module.exports =
    init: init

$main = void
items = []
num-items = -1
$container = void

container-width = -1
container-height = -1

span-widths = []
longest-width = -1
span-height-large = void

function init $_container, vals
    $container := $_container

    container-width := $container.width()

    num-items := vals.length

    $main = $ '<div>'
        ..attr 'id' project-name

    vals.for-each (v, i) ->
        inner = v
        $item = $ '<div>'
            #..html inner
            ..attr 'id' i
        $span = $ '<span>'
            ..html inner
        $main.append $item
        $item.append $span
        items.push $item

    $container.append $main

    container-height := $container.height()

function collapse n
    tops = []
    lefts = []
    items.for-each ($v) ->
        offset = $v.position()
        tops.push offset.top
        lefts.push offset.left

        $span = $v.find 'span'
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
        ->
            select n
            #collapse2 n
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

    #container-height = $container.height()
    log 'container-height' container-height
    log 'span-height-large' span-height-large

    j = -1
    items.for-each ($v, i) ->
        if i == n
            $v.css 'left' 0
            top = (container-height / 2) - (span-height-large / 2)
            $v.css 'top' top
        else
            j++
            $v.css 'left' longest-width + 15 # XX
            span-height-small = 10 # XX
            top = (container-height - span-height-small) / (num-items - 2) * j
            $v.css 'top' top


function collapse2 n
    width-last = span-widths[num-items - 1]
    # padding XX
    left-first = 0
    log 'width-last' width-last
    left-last = container-width - width-last
    log 'container-width' container-width
    log 'left-last' left-last
    available-width = left-last - left-first
    spacing = available-width / num-items

    items.for-each ($v, i) ->
        return
        left = left-first + spacing * i
        $v
            .css 'top' 0
            .css 'left' left

window.collapse = collapse
window.collapse2 = collapse2
