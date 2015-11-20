function log
    console.log.apply console, arguments

function warn
    args = [.. for &]
        ..unshift 'Warning:'
    console.warn.apply console, args

function ierror
    args = [].slice.call arguments .join ' '
    err = "Internal error: " + args

    if Error and (e = new Error args) and (s = e.stack)
        err = [err, s].join ' '
    log err

function is-str
    typeof! it is 'String'

function is-string
    typeof! it is 'String'

function is-bool
    typeof! it is 'Boolean'

function is-boolean
    typeof! it is 'Boolean'

function is-obj
    typeof! it is 'Object'

function is-object
    typeof! it is 'Object'

function is-array
    is-arr.apply this, arguments

function is-arr
    typeof! it is 'Array'

function is-num
    is-number it

/*
 * Checks the type of the argument, in the same way as is-str, is-arr, etc.
 * Use is-a-number to test strings such as '3.1'.
 *
 * If it's a Number, returns an object with property 'nan' (alias 'is-nan')
 * based on whether it's NaN (not a number).
 * 
 * Returns false otherwise.
 */
function is-number
    return false unless typeof! it is 'Number'
    nan = isNaN it

    nan: nan
    is-nan: nan

/*
 * Also returns true if the argument is a string representing a number.
 */
function is-a-num
    is-a-number it

function is-a-number
    if is-str it
        it = +it
        return false if isNaN it
    is-num it

function is-integer
    is-num it and it == Math.floor it

function is-int
    is-num it and it == Math.floor it

function is-positive-int
    is-int it and it > 0

function is-non-negative-int
    is-int it and it >= 0

# Mostly good enough.
# Be aware of floating point rounding issues in JS.
# 1.0049999999999999 == 1.005 for example.
function round decimals, number
    # e.g. round 52.77619 to 4 decimals:
    #   - multiply by 10^4, round to int, divide by 10^4.
    #   - then shave off extra 00000's an
    factor = Math.pow 10 decimals
    num = Math.round(number * factor) / factor
    # it *might* now be something like 52.7762000000001 or 52.776199999999
    # make into string, truncate, and back to num.
    + num.toFixed decimals


module.exports = {
    log, ierror, warn,
    is-str, is-string,
    is-bool, is-boolean,
    is-obj, is-object,
    is-array, is-arr,
    is-num, is-number,
    is-a-num, is-a-number,
    is-integer, is-int,
    is-positive-int, is-non-negative-int,
    round,
}
