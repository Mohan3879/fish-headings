var $, jquery, projectName, util, ref$, log, warn, config, our, toString$ = {}.toString;
$ = jquery = require('./lib/jquery');
projectName = 'fish-headings';
ref$ = util = require('./util'), log = ref$.log, warn = ref$.warn;
module.exports = {
  init: init,
  collapse: collapse,
  expand: expand,
  collapsedHeight: collapsedHeight,
  selected: selected,
  addListener: addListener
};
config = {
  'class': {
    headingEnabled: 'enabled',
    headingDisabled: 'disabled',
    containerCollapsed: 'collapsed'
  },
  collisionGutter: 100,
  maxTransitionTimeMs: 100
};
our = {
  items: [],
  $main: void 8,
  opts: {},
  tops: [],
  lefts: [],
  numItems: -1,
  selected: void 8,
  $container: void 8,
  containerWidth: -1,
  expandedHeight: -1,
  collapsedHeightInner: -1,
  collapsedHeight: -1,
  longestWidth: -1,
  flushLeft: void 8,
  paddingTop: -1,
  paddingBottom: -1
};
function init($_container, vals, opts){
  opts == null && (opts = {});
  our.$container = $_container;
  initMain(vals, opts);
  calculate();
  inject();
  return $(window).on('resize', function(){
    our.$container.empty();
    calculate();
    inject();
    if (our.selected != null) {
      return collapse(our.selected, true);
    }
  });
}
function collapse(n, force){
  if (our.selected === n && !force) {
    checkCollisions();
    return;
  }
  absolutise();
  return setTimeout(function(){
    return collapseDo(n);
  }, 0);
}
function collapseDo(n){
  var cntDisabled, modifiedCss;
  our.selected = n;
  our.$container.addClass(config['class'].containerCollapsed);
  our.items.forEach(function($v, i){
    $v.removeClass(config['class'].headingDisabled).removeClass(config['class'].headingEnabled);
    if (i === n) {
      return $v.addClass(config['class'].headingEnabled);
    } else {
      return $v.addClass(config['class'].headingDisabled);
    }
  });
  cntDisabled = -1;
  modifiedCss = 0;
  our.items.forEach(function($v, i){
    var modifyCssV, top, spanHeightSmall;
    modifyCssV = modifyCss.bind(null, $v);
    modifiedCss = modifiedCss + $v.css('left', '');
    if (i === n) {
      top = divide(our.collapsedHeightInner, 2) - our.spanHeightLarge / 2;
      return modifiedCss = modifiedCss + modifyCssV('top', top);
    } else {
      cntDisabled = cntDisabled + 1;
      spanHeightSmall = 10;
      top = function(){
        var height, delta;
        height = subtract(our.collapsedHeightInner, spanHeightSmall);
        delta = divide(height, our.numItems - 2);
        return multiply(delta, cntDisabled);
      }();
      return modifiedCss = modifiedCss + modifyCssV('top', top);
    }
  });
  return setTimeout(checkCollisions, config.maxTransitionTimeMs * 1.1);
}
function expand(){
  var x$;
  if (our.selected == null) {
    return;
  }
  x$ = our.$container;
  x$.removeClass(config['class'].containerCollapsed);
  x$.css('min-height', '');
  x$.css('max-height', '');
  restore();
  return our.selected = void 8;
}
function collapsedHeight(){
  return our.collapsedHeight;
}
function selected(){
  return our.selected;
}
function addListener(event, cb){
  if (event === '/collapsed-height') {
    return our.$main.on('/collapsed-height', function(){
      return cb(our.collapsedHeight);
    });
  } else {
    return warn("Invalid event", brightRed(event));
  }
}
function initMain(vals, _opts){
  var ref$, x$, $main;
  _opts == null && (_opts = {});
  our.numItems = vals.length;
  our.opts = _opts;
  our.flushLeft = (ref$ = _opts.flushLeft) != null ? ref$ : false;
  x$ = $main = $('<div>');
  x$.attr('id', projectName);
  vals.forEach(function(v, i){
    var text, href, listIconClass, x$, $item, $spanIcon, y$, $spanContents, z$, $spanText, z1$;
    if (toString$.call(v).slice(8, -1) === 'Object') {
      text = v.text, href = v.href, listIconClass = v.listIconClass;
      listIconClass == null && (listIconClass = []);
    } else {
      text = v;
      listIconClass = [];
    }
    x$ = $item = $('<div>');
    x$.attr('id', i);
    $spanIcon = $('<span>');
    listIconClass.forEach(function(it){
      return $spanIcon.addClass(it);
    });
    if (href) {
      y$ = $spanContents = $('<a>');
      y$.attr('href', href);
      y$.html(text);
      z$ = $spanText = $('<span>');
      z$.append($spanContents);
    } else {
      z1$ = $spanText = $('<span>');
      z1$.html(text);
    }
    $main.append($item);
    $item.append($spanIcon);
    $item.append($spanText);
    return our.items.push($item);
  });
  our.$main = $main;
  return our.items[0].on('transitionend', function(){
    if (our.disableTransitionend) {
      return;
    }
    return checkCollisions();
  });
}
function calculate(){
  var ref$, that;
  our.paddingTop = makeAbsolute((ref$ = our.opts.paddingTop) != null ? ref$ : 0, 'vertical');
  our.paddingBottom = makeAbsolute((ref$ = our.opts.paddingBottom) != null ? ref$ : 0, 'vertical');
  our.$container.css('padding-top', our.paddingTop).css('padding-bottom', our.paddingBottom);
  return our.collapsedHeightInner = (that = our.opts.collapsedHeightInner) ? makeAbsolute(that, 'vertical') : void 8;
}
function inject(){
  var collapsedInner, ref$;
  our.$container.append(our.$main);
  our.expandedHeight = our.$container.outerHeight();
  collapsedInner = (ref$ = our.collapsedHeightInner) != null
    ? ref$
    : our.expandedHeight;
  our.collapsedHeight = add(collapsedInner, our.paddingTop, our.paddingBottom);
  return our.$main.trigger('/collapsed-height');
}
function absolutise(){
  var tops, lefts;
  our.items.forEach(function($v, i){
    return $v.css('position', 'static');
  });
  tops = [];
  lefts = [];
  our.items.forEach(function($v, i){
    var offset, span, $span, width;
    offset = $v.position();
    tops.push(offset.top);
    lefts.push(offset.left);
    span = $v.find('span')[1];
    $span = $(span);
    width = $span.width();
    our.longestWidth = Math.max(width, our.longestWidth);
    if (i === 0) {
      return our.spanHeightLarge = $span.height();
    }
  });
  our.items.forEach(function($v, i){
    var top, left;
    top = tops[i];
    left = lefts[i];
    return $v.css('position', 'absolute').css('top', top).css('left', left);
  });
  our.$container.css('min-height', our.collapsedHeight);
  our.$container.css('max-height', our.collapsedHeight);
  our.tops = tops;
  return our.lefts = lefts;
}
function restore(){
  our.items.forEach(function($v, i){
    return $v.css('position', 'static').removeClass(config['class'].headingDisabled).addClass(config['class'].headingEnabled);
  });
  return our.$container.css('min-height', our.expandedHeight);
}
function op(theOp, values){
  var percentMode, result, reduce, k, j, i$, len$, i;
  percentMode = false;
  result = void 8;
  reduce = function(a, b){
    if (theOp === 'add') {
      return a + b;
    }
    if (theOp === 'subtract') {
      return a - b;
    }
    if (theOp === 'multiply') {
      return a * b;
    }
    if (theOp === 'divide') {
      return a / b;
    }
  };
  k = -1;
  j = '';
  for (i$ = 0, len$ = values.length; i$ < len$; ++i$) {
    i = values[i$];
    k++;
    i += '';
    j = i;
    i = i.replace(/%$/, '');
    if (i !== j) {
      percentMode = true;
    }
    if (k === 0) {
      result = +i;
    } else {
      result = reduce(result, +i);
    }
  }
  if (percentMode) {
    result += '%';
  }
  return result;
}
function add(){
  return op('add', (function(args$){
    var i$, x$, len$, results$ = [];
    for (i$ = 0, len$ = args$.length; i$ < len$; ++i$) {
      x$ = args$[i$];
      results$.push(x$);
    }
    return results$;
  }(arguments)));
}
function subtract(){
  return op('subtract', (function(args$){
    var i$, x$, len$, results$ = [];
    for (i$ = 0, len$ = args$.length; i$ < len$; ++i$) {
      x$ = args$[i$];
      results$.push(x$);
    }
    return results$;
  }(arguments)));
}
function divide(){
  return op('divide', (function(args$){
    var i$, x$, len$, results$ = [];
    for (i$ = 0, len$ = args$.length; i$ < len$; ++i$) {
      x$ = args$[i$];
      results$.push(x$);
    }
    return results$;
  }(arguments)));
}
function multiply(){
  return op('multiply', (function(args$){
    var i$, x$, len$, results$ = [];
    for (i$ = 0, len$ = args$.length; i$ < len$; ++i$) {
      x$ = args$[i$];
      results$.push(x$);
    }
    return results$;
  }(arguments)));
}
function makeAbsolute(val, direction){
  var m, $theReference, theReferenceVal;
  m = /^(.+)%$/.exec(val);
  if (!m) {
    return val;
  }
  $theReference = $(window);
  theReferenceVal = direction === 'horizontal'
    ? $theReference.width()
    : $theReference.height();
  return m[1] * theReferenceVal / 100;
}
function checkCollisions(){
  var leftStuffRightEdge, rightStuffLeftEdge, theClass, $find;
  leftStuffRightEdge = -1;
  rightStuffLeftEdge = -1;
  our.items.forEach(function($v, i){
    return $v.show();
  });
  our.items.forEach(function($v, i){
    if ($v.hasClass(config['class'].headingEnabled)) {
      leftStuffRightEdge = $v.offset().left + $v.width();
    } else if ($v.hasClass(config['class'].headingDisabled)) {
      rightStuffLeftEdge = $v.offset().left;
    }
    if (rightStuffLeftEdge != null && leftStuffRightEdge != null) {
      return;
    }
  });
  if (rightStuffLeftEdge <= leftStuffRightEdge + config.collisionGutter) {
    theClass = '.' + config['class'].headingDisabled;
    $find = our.$container.find(theClass).hide();
  }
  return 1;
}
function modifyCss($target, prop, value){
  var curVal;
  curVal = $target.css(prop);
  $target.css(prop, value);
  return curVal !== value;
}