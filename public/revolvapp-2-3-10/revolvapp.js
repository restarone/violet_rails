/*
    Revolvapp
    Version 2.3.10
    Updated: September 14, 2023

    http://imperavi.com/revolvapp/

    Copyright (c) 2009-2023, Imperavi Ltd.
    License: http://imperavi.com/revolvapp/license/
*/
(function() {


// Version 2.0
var Ajax = {};

Ajax.settings = {};
Ajax.post = function(options) { return new AjaxRequest('post', options); };
Ajax.get = function(options) { return new AjaxRequest('get', options); };
Ajax.request = function(method, options) { return new AjaxRequest(method, options); };

var AjaxRequest = function(method, options) {
    var defaults = {
        method: method,
        url: '',
        before: function() {},
        success: function() {},
        error: function() {},
        data: false,
        async: true,
        headers: {}
    };

    this.p = this.extend(defaults, options);
    this.p = this.extend(this.p, Ajax.settings);
    this.p.method = this.p.method.toUpperCase();

    this.prepareData();

    this.xhr = new XMLHttpRequest();
    this.xhr.open(this.p.method, this.p.url, this.p.async);

    this.setHeaders();

    var before = (typeof this.p.before === 'function') ? this.p.before(this.xhr) : true;
    if (before !== false) {
        this.send();
    }
};

AjaxRequest.prototype = {
    extend: function(obj1, obj2) {
        if (obj2) {
            Object.keys(obj2).forEach(function(key) {
                obj1[key] = obj2[key];
            });
        }
        return obj1;
    },
    prepareData: function() {
        if (['POST', 'PUT'].indexOf(this.p.method) !== -1 && !this.isFormData()) this.p.headers['Content-Type'] = 'application/x-www-form-urlencoded';
        if (typeof this.p.data === 'object' && !this.isFormData()) this.p.data = this.toParams(this.p.data);
        if (this.p.method === 'GET') {
            var sign = (this.p.url.search(/\?/) !== -1) ? '&' : '?';
            this.p.url = (this.p.data) ? this.p.url + sign + this.p.data : this.p.url;
        }
    },
    setHeaders: function() {
        this.xhr.setRequestHeader('X-Requested-With', this.p.headers['X-Requested-With'] || 'XMLHttpRequest');
        Object.keys(this.p.headers).forEach(function(key) {
            this.xhr.setRequestHeader(key, this.p.headers[key]);
        }.bind(this));
    },
    isFormData: function() {
        return (typeof window.FormData !== 'undefined' && this.p.data instanceof window.FormData);
    },
    isComplete: function() {
        return !(this.xhr.status < 200 || (this.xhr.status >= 300 && this.xhr.status !== 304));
    },
    send: function() {
        if (this.p.async) {
            this.xhr.onload = this.loaded.bind(this);
            this.xhr.send(this.p.data);
        }
        else {
            this.xhr.send(this.p.data);
            this.loaded.call(this);
        }
    },
    loaded: function() {
        var response;
        if (this.isComplete()) {
            response = this.parseResponse();
            if (typeof this.p.success === 'function') this.p.success(response, this.xhr);
        }
        else {
            response = this.parseResponse();
            if (typeof this.p.error === 'function') this.p.error(response, this.xhr, this.xhr.status);
        }
    },
    parseResponse: function() {
        var response = this.xhr.response;
        var json = this.parseJson(response);
        return (json) ? json : response;
    },
    parseJson: function(str) {
        try {
            var o = JSON.parse(str);
            if (o && typeof o === 'object') {
                return o;
            }

        } catch (e) {
            return false;
        }

        return false;
    },
    toParams: function (obj) {
        return Object.keys(obj).map(
            function(k){ return encodeURIComponent(k) + '=' + encodeURIComponent(obj[k]); }
        ).join('&');
    }
};
// Version 2.0
var DomCache = [0];
var DomExpando = 'data' + new Date().getTime();

var Dom = function(selector, context) {
    return this.parse(selector, context);
};

Dom.ready = function(fn) {
    document.addEventListener('DOMContentLoaded', fn);
};

Dom.prototype = {
    get length() {
        return this.nodes.length;
    },
    parse: function(s, c) {
        var n;
        var rehtml = /^\s*<(\w+|!)[^>]*>/;

        if (!s) {
            n = [];
        }
        else if (s instanceof Dom) {
            this.nodes = s.nodes;
            return s;
        }
        else if (rehtml.test(s)) {
            n = this.create(s);
        }
        else if (typeof s !== 'string') {
            if (s.nodeType && s.nodeType === 11) n = s.childNodes;
            else n = (s.nodeType || this._isWindowNode(s)) ? [s] : s;
        }
        else {
            n = this._query(s, c);
        }

        this.nodes = this._slice(n);
    },
    create: function(html) {
        if (/^<(\w+)\s*\/?>(?:<\/\1>|)$/.test(html)) {
            return [document.createElement(RegExp.$1)];
        }

        var elmns = [];
        var c = document.createElement('div');
        c.innerHTML = html;
        for (var i = 0, l = c.childNodes.length; i < l; i++) {
            elmns.push(c.childNodes[i]);
        }

        return elmns;
    },

    // dataset/dataget
    dataset: function(key, value) {
        return this.each(function($node) {
            DomCache[this.dataindex($node.get())][key] = value;
        });
    },
    dataget: function(key) {
        return DomCache[this.dataindex(this.get())][key];
    },
    dataindex: function(el) {
        var index = el[DomExpando];
        var nextIndex = DomCache.length;

        if (!index) {
            index = nextIndex;
            if (el) el[DomExpando] = nextIndex;
            DomCache[index] = {};
        }

        return index;
    },

    // add
    add: function(n) {
        this.nodes = this.nodes.concat(this._array(n));
        return this;
    },

    // get
    get: function(index) {
        return this.nodes[(index || 0)] || false;
    },
    getAll: function() {
        return this.nodes;
    },
    eq: function(index) {
        return new Dom(this.nodes[index]);
    },
    first: function() {
        return new Dom(this.nodes[0]);
    },
    last: function() {
        return new Dom(this.nodes[this.nodes.length - 1]);
    },
    contents: function() {
        return this.get().childNodes;
    },

    // loop
    each: function(fn) {
        var len = this.nodes.length;
        for (var i = 0; i < len; i++) {
            fn.call(this, new Dom(this.nodes[i]), i);
        }

        return this;
    },

    // traversing
    is: function(s) {
        return (this.filter(s).length > 0);
    },
    filter: function (s) {
        var fn;
        if (s === undefined) {
            return this;
        }
        else if (typeof s === 'function') {
            fn = function(node) { return s(new Dom(node)); };
        }
        else {
            fn = function(node) {
                if ((s && s.nodeType) || s instanceof Node) {
                    return (s === node);
                }
                else {
                    node.matches = node.matches || node.msMatchesSelector || node.webkitMatchesSelector;
                    return (node.nodeType === 1) ? node.matches(s || '*') : false;
                }
            };
        }

        return new Dom(this.nodes.filter.call(this.nodes, fn));
    },
    not: function(filter) {
        return this.filter(function(node) { return !new Dom(node).is(filter || true); });
    },
    find: function(s) {
        var n = [];
        this.each(function($n) {
            var node = $n.get();
            var ns = this._query(s, node);
            for (var i = 0; i < ns.length; i++) {
                n.push(ns[i]);
            }
        });

        return new Dom(n);
    },
    children: function(s) {
        var n = [];
        this.each(function($n) {
            var node = $n.get();
            if (node.children) {
                var ns = node.children;
                for (var i = 0; i < ns.length; i++) {
                    n.push(ns[i]);
                }
            }
        });

        return new Dom(n).filter(s);
    },
    parent: function(s) {
        var node = this.get();
        var p = (node.parentNode) ? node.parentNode : false;
        return (p) ? new Dom(p).filter(s) : new Dom();
    },
    parents: function(s, c) {
        c = this._context(c);

        var n = [];
        this.each(function($n) {
            var node = $n.get();
            var p = node.parentNode;
            while (p && p !== c) {
                if (s) {
                    if (new Dom(p).is(s)) { n.push(p); }
                }
                else {
                    n.push(p);
                }

                p = p.parentNode;
            }
        });

        return new Dom(n);
    },
    closest: function(s, c) {
        c = this._context(c);

        var n = [];
        var isNode = (s && s.nodeType);
        this.each(function($n) {
            var node = $n.get();
            do {
                if (node && ((isNode && node === s) || new Dom(node).is(s))) {
                    return n.push(node);
                }
            } while ((node = node.parentNode) && node !== c);
        });

        return new Dom(n);
    },
    next: function(s) {
        return this._sibling(s, 'nextSibling');
    },
    nextElement: function(s) {
        return this._sibling(s, 'nextElementSibling');
    },
    prev: function(s) {
        return this._sibling(s, 'previousSibling');
    },
    prevElement: function(s) {
        return this._sibling(s, 'previousElementSibling');
    },

    // css
    css: function(name, value) {
        if (value === undefined && (typeof name !== 'object')) {
            var node = this.get();
            if (name === 'width' || name === 'height') {
                return (node.style) ? this._getHeightOrWidth(name) + 'px' : undefined;
            }
            else {
                return (node.style) ? getComputedStyle(node, null)[name] : undefined;
            }
        }

        // set
        return this.each(function($n) {
            var node = $n.get();
            var o = {};
            if (typeof name === 'object') o = name;
            else o[name] = value;

            for (var key in o) {
                if (node.style) node.style[key] = o[key];
            }
        });
    },

    // attr
    attr: function(name, value, data) {
        data = (data) ? 'data-' : '';

        if (typeof value === 'undefined' && (typeof name !== 'object')) {
            var node = this.get();
            if (node && node.nodeType !== 3) {
                return (name === 'checked') ? node.checked : this._boolean(node.getAttribute(data + name));
            }
            else {
                return;
            }
        }

        // set
        return this.each(function($n) {
            var node = $n.get();
            var o = {};
            if (typeof name === 'object') o = name;
            else o[name] = value;

            for (var key in o) {
                if (node.nodeType !== 3) {
                    if (key === 'checked') node.checked = o[key];
                    else node.setAttribute(data + key, o[key]);
                }
            }
        });
    },
    data: function(name, value) {
        if (name === undefined || name === true) {
            var reDataAttr = /^data-(.+)$/;
            var attrs = this.get().attributes;

            var data = {};
            var replacer = function (g) { return g[1].toUpperCase(); };

            for (var key in attrs) {
                if (attrs[key] && reDataAttr.test(attrs[key].nodeName)) {
                    var dataName = attrs[key].nodeName.match(reDataAttr)[1];
                    var val = attrs[key].value;
                    if (name !== true) {
                        dataName = dataName.replace(/-([a-z])/g, replacer);
                    }

                    if (val.search(/^{/) !== -1) val = this._object(val);
                    else val = (this._number(val)) ? parseFloat(val) : this._boolean(val);

                    data[dataName] = val;
                }
            }

            return data;
        }

        return this.attr(name, value, true);
    },
    val: function(value) {
        if (value === undefined) {
            var el = this.get();
            if (el.type && el.type === 'checkbox') return el.checked;
            else return el.value;
        }

        return this.each(function($n) {
            var el = $n.get();
            if (el.type && el.type === 'checkbox') el.checked = value;
            else el.value = value;
        });
    },
    removeAttr: function(value) {
        return this.each(function($n) {
            var node = $n.get();
            var fn = function(name) { if (node.nodeType !== 3) node.removeAttribute(name); };
            value.split(' ').forEach(fn);
        });
    },

    // class
    addClass: function(value) {
        return this._eachClass(value, 'add');
    },
    removeClass: function(value) {
        return this._eachClass(value, 'remove');
    },
    toggleClass: function(value) {
        return this._eachClass(value, 'toggle');
    },
    hasClass: function(value) {
        var node = this.get();
        return (node.classList) ? node.classList.contains(value) : false;
    },

    // html & text
    empty: function() {
        return this.each(function($n) { $n.get().innerHTML = ''; });
    },
    html: function(html) {
        return (html === undefined) ? (this.get().innerHTML || '') : this.empty().append(html);
    },
    text: function(text) {
        return (text === undefined) ? (this.get().textContent || '') : this.each(function($n) { $n.get().textContent = text; });
    },

    // manipulation
    after: function(html) {
        return this._inject(html, function(frag, node) {
            if (typeof frag === 'string') {
                node.insertAdjacentHTML('afterend', frag);
            }
            else {
                if (node.parentNode !== null) {
                    for (var i = frag instanceof Node ? [frag] : this._array(frag).reverse(), s = 0; s < i.length; s++) {
                        node.parentNode.insertBefore(i[s], node.nextSibling);
                    }
                }
            }

            return node;
        });
    },
    before: function(html) {
        return this._inject(html, function(frag, node) {
            if (typeof frag === 'string') {
                node.insertAdjacentHTML('beforebegin', frag);
            }
            else {
                var elms = (frag instanceof Node) ? [frag] : this._array(frag);
                for (var i = 0; i < elms.length; i++) {
                    node.parentNode.insertBefore(elms[i], node);
                }
            }

            return node;
        });
    },
    append: function(html) {
        return this._inject(html, function(frag, node) {
            if (typeof frag === 'string' || typeof frag === 'number') {
                node.insertAdjacentHTML('beforeend', frag);
            }
            else {
                var elms = (frag instanceof Node) ? [frag] : this._array(frag);
                for (var i = 0; i < elms.length; i++) {
                    node.appendChild(elms[i]);
                }
            }

            return node;
        });
    },
    prepend: function(html) {
        return this._inject(html, function(frag, node) {
            if (typeof frag === 'string' || typeof frag === 'number') {
                node.insertAdjacentHTML('afterbegin', frag);
            }
            else {
                var elms = (frag instanceof Node) ? [frag] : this._array(frag).reverse();
                for (var i = 0; i < elms.length; i++) {
                    node.insertBefore(elms[i], node.firstChild);
                }
            }

            return node;
        });
    },
    wrap: function(html) {
        return this._inject(html, function(frag, node) {
            var wrapper = (typeof frag === 'string' || typeof frag === 'number') ? this.create(frag)[0] : (frag instanceof Node) ? frag : this._array(frag)[0];

            if (node.parentNode) {
                node.parentNode.insertBefore(wrapper, node);
            }

            wrapper.appendChild(node);
            return wrapper;
        });
    },
    unwrap: function() {
        return this.each(function($n) {
            var node = $n.get();
            var docFrag = document.createDocumentFragment();
            while (node.firstChild) {
                var child = node.removeChild(node.firstChild);
                docFrag.appendChild(child);
            }

            node.parentNode.replaceChild(docFrag, node);
        });
    },
    replaceWith: function(html) {
        return this._inject(html, function(frag, node) {
            var docFrag = document.createDocumentFragment();
            var elms = (typeof frag === 'string' || typeof frag === 'number') ? this.create(frag) : (frag instanceof Node) ? [frag] : this._array(frag);

            for (var i = 0; i < elms.length; i++) {
                docFrag.appendChild(elms[i]);
            }

            var result = docFrag.childNodes[0];
            if (node.parentNode) {
                node.parentNode.replaceChild(docFrag, node);
            }

            return result;
        });
    },
    remove: function() {
        return this.each(function($n) {
            var node = $n.get();
            if (node.parentNode) node.parentNode.removeChild(node);
        });
    },
    clone: function(events) {
        var n = [];
        this.each(function($n) {
            var node = $n.get();
            var copy = this._clone(node);
            if (events) copy = this._cloneEvents(node, copy);
            n.push(copy);
        });

        return new Dom(n);
    },

    // show/hide
    show: function() {
        return this.each(function($n) {
            var node = $n.get();
            if (!node.style || !this._hasDisplayNone(node)) return;

            var target = node.getAttribute('domTargetShow');
            node.style.display = (target) ? target : 'block';
            node.removeAttribute('domTargetShow');

        }.bind(this));
    },
    hide: function() {
        return this.each(function($n) {
            var node = $n.get();
            if (!node.style || this._hasDisplayNone(node)) return;

            var display = node.style.display;
            if (display !== 'block') node.setAttribute('domTargetShow', display);
            node.style.display = 'none';
        });
    },

    // dimensions
    scrollTop: function(value) {
        var node = this.get();
        var isWindow = this._isWindowNode(node);
        var isDocument = (node.nodeType === 9);
        var el = (isDocument) ? (node.scrollingElement || node.body.parentNode || node.body || node.documentElement) : node;

        if (typeof value !== 'undefined') {
            value = parseInt(value);
            if (isWindow) node.scrollTo(0, value);
            else el.scrollTop = value;
            return;
        }

        return (isWindow) ? node.pageYOffset : el.scrollTop;
    },
    offset: function() {
        return this._getPos('offset');
    },
    position: function() {
        return this._getPos('position');
    },
    width: function(value) {
        return (value !== undefined) ? this.css('width', parseInt(value) + 'px') : this._getSize('width', 'Width');
    },
    height: function(value) {
        return (value !== undefined) ? this.css('height', parseInt(value) + 'px') : this._getSize('height', 'Height');
    },
    outerWidth: function() {
        return this._getSize('width', 'Width', 'outer');
    },
    outerHeight: function() {
        return this._getSize('height', 'Height', 'outer');
    },
    innerWidth: function() {
        return this._getSize('width', 'Width', 'inner');
    },
    innerHeight: function() {
        return this._getSize('height', 'Height', 'inner');
    },

    // events
    click: function() {
        return this._trigger('click');
    },
    focus: function() {
        return this._trigger('focus');
    },
    blur: function() {
        return this._trigger('blur');
    },
    on: function(names, handler, one) {
        return this.each(function($n) {
            var node = $n.get();
            var events = names.split(' ');
            for (var i = 0; i < events.length; i++) {
                var event = this._getEventName(events[i]);
                var namespace = this._getEventNamespace(events[i]);

                handler = (one) ? this._getOneHandler(handler, names) : handler;
                node.addEventListener(event, handler);

                node._e = node._e || {};
                node._e[namespace] = node._e[namespace] || {};
                node._e[namespace][event] = node._e[namespace][event] || [];
                node._e[namespace][event].push(handler);
            }

        });
    },
    one: function(events, handler) {
        return this.on(events, handler, true);
    },
    off: function(names, handler) {
        var testEvent = function(name, key, event) { return (name === event); };
        var testNamespace = function(name, key, event, namespace) { return (key === namespace); };
        var testEventNamespace = function(name, key, event, namespace) { return (name === event && key === namespace); };
        var testPositive = function() { return true; };

        if (names === undefined) {
            // all
            return this.each(function($n) {
                this._offEvent($n.get(), false, false, handler, testPositive);
            });
        }

        return this.each(function($n) {
            var node = $n.get();
            var events = names.split(' ');

            for (var i = 0; i < events.length; i++) {
                var event = this._getEventName(events[i]);
                var namespace = this._getEventNamespace(events[i]);

                // 1) event without namespace
                if (namespace === '_events') this._offEvent(node, event, namespace, handler, testEvent);
                // 2) only namespace
                else if (!event && namespace !== '_events') this._offEvent(node, event, namespace, handler, testNamespace);
                // 3) event + namespace
                else this._offEvent(node, event, namespace, handler, testEventNamespace);
            }
        });
    },

    // form
    serialize: function(asObject) {
        var obj = {};
        var elms = this.get().elements;
        for (var i = 0; i < elms.length; i++) {
            var el = elms[i];
            if (/(checkbox|radio)/.test(el.type) && !el.checked) continue;
            if (!el.name || el.disabled || el.type === 'file') continue;

            if (el.type === 'select-multiple') {
                for (var z = 0; z < el.options.length; z++) {
                    var opt = el.options[z];
                    if (opt.selected) obj[el.name] = opt.value;
                }
            }

            obj[el.name] = (this._number(el.value)) ? parseFloat(el.value) : this._boolean(el.value);
        }

        return (asObject) ? obj : this._params(obj);
    },

    // animation
    scroll: function() {
        this.get().scrollIntoView({ behavior: 'smooth' });
    },
    fadeIn: function(speed, fn) {
        var anim = this._anim(speed, fn, 500);

        return this.each(function($n) {
            $n.css({ 'display': 'block', 'opacity': 0, 'animation': 'fadeIn ' + anim.speed + 's ease-in-out' }).removeClass('hidden');
            $n.one('animationend', function() {
                $n.css({ 'opacity': '', 'animation': '' });
                if (anim.fn) anim.fn($n);
            });
        });
    },
    fadeOut: function(speed, fn) {
        var anim = this._anim(speed, fn, 300);

        return this.each(function($n) {
            $n.css({ 'opacity': 1, 'animation': 'fadeOut ' + anim.speed + 's ease-in-out' });
            $n.one('animationend', function() {
                $n.css({ 'display': 'none', 'opacity': '', 'animation': '' });
                if (anim.fn) anim.fn($n);
            });
        });
    },
    slideUp: function(speed, fn) {
        var anim = this._anim(speed, fn, 300);

        return this.each(function($n) {
            $n.height($n.height());
            $n.css({ 'overflow': 'hidden', 'animation': 'slideUp ' + anim.speed + 's ease-out' });
            $n.one('animationend', function() {
                $n.css({ 'display': 'none', 'height': '', 'animation': '' });
                if (anim.fn) anim.fn($n);
            });
        });
    },
    slideDown: function(speed, fn) {
        var anim = this._anim(speed, fn, 400);

        return this.each(function($n) {
            $n.height($n.height());
            $n.css({ 'display': 'block', 'overflow': 'hidden', 'animation': 'slideDown ' + anim.speed + 's ease-in-out' }).removeClass('hidden');
            $n.one('animationend', function() {
                $n.css({ 'overflow': '', 'height': '', 'animation': '' });
                if (anim.fn) anim.fn($n);
            });
        });
    },

    // private
    _queryContext: function(s, c) {
        c = this._context(c);
        return (c.nodeType !== 3 && typeof c.querySelectorAll === 'function') ? c.querySelectorAll(s) : [];
    },
    _query: function(s, c) {
        var d = document;
        if (c) {
            return this._queryContext(s, c);
        }
        else if (/^[.#]?[\w-]*$/.test(s)) {
            if (s[0] === '#') {
                var el = d.getElementById(s.slice(1));
                return el ? [el] : [];
            }
            if (s[0] === '.') {
                return d.getElementsByClassName(s.slice(1));
            }

            return d.getElementsByTagName(s);
        }

        return d.querySelectorAll(s);
    },
    _context: function(c) {
        return (!c) ? document : ((typeof c === 'string') ? document.querySelector(c) : c);
    },
    _sibling: function(s, method) {
        var isNode = (s && s.nodeType);
        var sibling;

        this.each(function($n) {
            var node = $n.get();
            do {
                node = node[method];
                 if (node && ((isNode && node === s) || new Dom(node).is(s))) {
                    sibling = node;
                    return;
                }
            }
            while (node);
        });

        return new Dom(sibling);
    },
    _slice: function(o) {
        return (!o || o.length === 0) ? [] : (o.length) ? [].slice.call(o.nodes || o) : [o];
    },
    _array: function(o) {
        if (o === undefined) return [];
        else if (o instanceof NodeList) {
            var arr = [];
            for (var i = 0; i < o.length; i++) {
                arr[i] = o[i];
            }

            return arr;
        }

        return (o instanceof Dom) ? o.nodes : o;
    },
    _object: function(str) {
        var jsonStr = str.replace(/(\w+:)|(\w+ :)/g, function(matchedStr) {
            return '"' + matchedStr.substring(0, matchedStr.length - 1) + '":';
        });

        return JSON.parse(jsonStr);
    },
    _params: function(obj) {
        var params = '';
        Object.keys(obj).forEach(function(key) {
            params += '&' + this._encodeUri(key) + '=' + this._encodeUri(obj[key]);
        }.bind(this));

        return params.replace(/^&/, '');
    },
    _boolean: function(str) {
        if (str === 'true') return true;
        else if (str === 'false') return false;

        return str;
    },
    _number: function(str) {
        return !isNaN(str) && !isNaN(parseFloat(str));
    },
    _inject: function(html, fn) {
        var len = this.nodes.length;
        var nodes = [];
        while (len--) {
            var res = (typeof html === 'function') ? html.call(this, this.nodes[len]) : html;
            var el = (len === 0) ? res : this._clone(res);
            var node = fn.call(this, el, this.nodes[len]);

            if (node) {
                if (node.dom) nodes.push(node.get());
                else nodes.push(node);
            }
        }

        return new Dom(nodes);
    },
    _clone: function(node) {
        if (typeof node === 'undefined') return;
        if (typeof node === 'string') return node;
        else if (node instanceof Node || node.nodeType) return node.cloneNode(true);
        else if ('length' in node) {
            return [].map.call(this._array(node), function(el) { return el.cloneNode(true); });
        }
    },
    _cloneEvents: function(node, copy) {
        var events = node._e;
        if (events) {
            copy._e = events;
            for (var name in events._events) {
                if (events._events.hasOwnProperty(name)) {
                    for (var i = 0; i < events._events[name].length; i++) {
                        copy.addEventListener(name, events._events[name][i]);
                    }
                }
            }
        }

        return copy;
    },
    _trigger: function(name) {
        var node = this.get();
        if (node && node.nodeType !== 3) node[name]();
        return this;
    },
    _encodeUri: function(str) {
        return encodeURIComponent(str).replace(/!/g, '%21').replace(/'/g, '%27').replace(/\(/g, '%28').replace(/\)/g, '%29').replace(/\*/g, '%2A').replace(/%20/g, '+');
    },
    _getSize: function(name, cname) {
        var el = this.get();
        var value = 0;
        if (el.nodeType === 3) {
            value = 0;
        }
        else if (el.nodeType === 9) {
            value = this._getDocSize(el, cname);
        }
        else if (this._isWindowNode(el)) {
            value = window['inner' + cname];
        }
        else {
            value = this._getHeightOrWidth(name);
        }

        return Math.round(value);
    },
    _getDocSize: function(node, type) {
        var body = node.body, html = node.documentElement;
        return Math.max(body['scroll' + type], body['offset' + type], html['client' + type], html['scroll' + type], html['offset' + type]);
    },
    _getPos: function(type) {
        var node = this.get();
        var dim = { top: 0, left: 0 };
        if (node.nodeType === 3 || this._isWindowNode(node) || node.nodeType === 9) {
            return dim;
        }
        else if (type === 'position') {
            return { top: node.offsetTop, left: node.offsetLeft };
        }
        else if (type === 'offset') {
            var rect = node.getBoundingClientRect();
            var doc = node.ownerDocument;
            var docElem = doc.documentElement;
            var win = doc.defaultView;

            return {
                top: rect.top + win.pageYOffset - docElem.clientTop,
                left: rect.left + win.pageXOffset - docElem.clientLeft
            };
        }

        return dim;
    },
    _getHeightOrWidth: function(name, type) {
        var cname = name.charAt(0).toUpperCase() + name.slice(1);
        var mode = (type) ? type : 'offset';
        var result = 0;
        var el = this.get();
        var style = getComputedStyle(el, null);
        var $targets = this.parents().filter(function($n) {
            var node = $n.get();
            return (node.nodeType === 1 && getComputedStyle(node, null).display === 'none') ? node : false;
        });

        if (style.display === 'none') $targets.add(el);
        if ($targets.length !== 0) {
            var fixStyle = 'visibility: hidden !important; display: block !important;';
            var tmp = [];

            $targets.each(function($n) {
                var thisStyle = $n.attr('style');
                if (thisStyle !== null) tmp.push(thisStyle);
                $n.attr('style', (thisStyle !== null) ? thisStyle + ';' + fixStyle : fixStyle);
            });

            result = el[mode + cname];

            $targets.each(function($n, i) {
                if (tmp[i] === undefined) $n.removeAttr('style');
                else $n.attr('style', tmp[i]);
            });
        }
        else {
            result = el[mode + cname];
        }

        return result;
    },
    _eachClass: function(value, type) {
        return this.each(function($n) {
            if (value) {
                var node = $n.get();
                var fn = function(name) { if (node.classList) node.classList[type](name); };
                value.split(' ').forEach(fn);
            }
        });
    },
    _getOneHandler: function(handler, events) {
        var self = this;
        return function() {
            handler.apply(this, arguments);
            self.off(events);
        };
    },
    _getEventNamespace: function(event) {
        var arr = event.split('.');
        var namespace = (arr[1]) ? arr[1] : '_events';
        return (arr[2]) ? namespace + arr[2] : namespace;
    },
    _getEventName: function(event) {
        return event.split('.')[0];
    },
    _offEvent: function(node, event, namespace, handler, condition) {
        for (var key in node._e) {
            if (node._e.hasOwnProperty(key)) {
                for (var name in node._e[key]) {
                    if (condition(name, key, event, namespace)) {
                        var handlers = node._e[key][name];
                        for (var i = 0; i < handlers.length; i++) {
                            if (typeof handler !== 'undefined' && handlers[i].toString() !== handler.toString()) {
                                continue;
                            }

                            node.removeEventListener(name, handlers[i]);
                            node._e[key][name].splice(i, 1);

                            if (node._e[key][name].length === 0) delete node._e[key][name];
                            if (Object.keys(node._e[key]).length === 0) delete node._e[key];
                        }
                    }
                }
            }
        }
    },
    _hasDisplayNone: function(el) {
        return (el.style.display === 'none') || ((el.currentStyle) ? el.currentStyle.display : getComputedStyle(el, null).display) === 'none';
    },
    _anim: function(speed, fn, speedDef) {
        if (typeof speed === 'function') {
            fn = speed;
            speed = speedDef;
        }
        else {
            speed = speed || speedDef;
        }

        return {
            fn: fn,
            speed: speed/1000
        };
    },
    _isWindowNode: function(node) {
        return (node === window || (node.parent && node.parent === window));
    }
};
// Init
var Revolvapp = function(selector, settings) {
    return RevolvappInit(selector, settings);
};

// Class
var RevolvappInit = function(selector, settings) {
    var instance;
    var namespace = 'revolvapp';
    var $el = $RE.dom(selector);
    if ($el.length !== 0) {
        instance = $el.dataget(namespace);

        // Initialization
        if (!instance) {
            instance = new App($el, settings);
            $el.dataset(namespace, instance);
        }
    }

    return instance;
};

var $RE = Revolvapp;

// Dom & Ajax
$RE.dom = function(selector, context) { return new Dom(selector, context); };
$RE.ajax = Ajax;

// Globals
$RE.prefix = 'rex';
$RE.version = '2.3.10';
$RE.settings = {};
$RE.lang = {};
$RE._store = {};
$RE._mixins = {};
$RE._subscribe = {};
$RE.keycodes = {
    BACKSPACE: 8,
    DELETE: 46,
    UP: 38,
    DOWN: 40,
    ENTER: 13,
    SPACE: 32,
    ESC: 27,
    TAB: 9,
    CTRL: 17,
    META: 91,
    SHIFT: 16,
    ALT: 18,
    RIGHT: 39,
    LEFT: 37
};

// Add
$RE.add = function(type, name, obj) {
    // translations
    if (obj.translations) {
        Revolvapp.lang = $RE.extend(true, $RE.lang, obj.translations);
    }

    // defaults
    if (obj.defaults) {
        var localopts = {};
        localopts[name] = obj.defaults;
        Revolvapp.opts = $RE.extend(true, $RE.opts, localopts);
    }

    // mixin
    if (type === 'mixin') {
        $RE._mixins[name] = obj;
    }
    else {
        // subscribe
        if (obj.subscribe) {
            for (var key in obj.subscribe) {
                if (obj.subscribe.hasOwnProperty(key)) {
                    if (typeof $RE._subscribe[key] === 'undefined') {
                        $RE._subscribe[key] = [];
                    }

                    var event = {
                        module: name,
                        func: obj.subscribe[key]
                    };

                    $RE._subscribe[key].push(event);
                }
            }
        }

        // prototype
        var F = function() {};
        F.prototype = obj;

        // mixins
        if (obj.mixins) {
            for (var i = 0; i < obj.mixins.length; i++) {
                $RE.inherit(F, $RE._mixins[obj.mixins[i]]);
            }
        }

        // store
        $RE._store[name] = { type: type, proto: F };
    }
};

// Lang
$RE.addLang = function(lang, obj) {
    if (typeof $RE.lang[lang] === 'undefined') {
        $RE.lang[lang] = {};
    }

    $RE.lang[lang] = $RE.extend(true, Revolvapp.lang[lang], obj);
};

// Inherit
$RE.inherit = function(current, parent) {
    var F = function() {};
    F.prototype = parent;
    var f = new F();

    for (var prop in current.prototype) {
        if (current.prototype.__lookupGetter__(prop)) {
            f.__defineGetter__(prop, current.prototype.__lookupGetter__(prop));
        }
        else {
            f[prop] = current.prototype[prop];
        }
    }

    current.prototype = f;
    current.prototype.super = parent;

    return current;
};

// Error
$RE.error = function(exception) {
    throw exception;
};

// Extend
$RE.extend = function() {
    var extended = {};
    var deep = false;
    var i = 0;
    var length = arguments.length;

    if (Object.prototype.toString.call(arguments[0]) === '[object Boolean]') {
        deep = arguments[0];
        i++;
    }

    var merge = function(obj) {
        for (var prop in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, prop)) {
                if (deep && Object.prototype.toString.call(obj[prop]) === '[object Object]') {
                    extended[prop] = $RE.extend(true, extended[prop], obj[prop]);
                }
                else {
                    extended[prop] = obj[prop];
                }
            }
        }
    };

    for (; i < length; i++) {
        var obj = arguments[i];
        merge(obj);
    }

    return extended;
};
Revolvapp.opts = {
    plugins: [],
    pluginsCss: [],
    source: true,
    bsmodal: false,
    content: false,
    lang: 'en',
    direction: 'ltr',
    editor: {
        font: 'Helvetica, Arial, sans-serif',
        lang: 'en',
        direction: 'ltr',
        https: false,
        path: false,
        template: false,
        images: false,
        viewOnly: false,
        spellcheck: true,
        grammarly: false,
        notranslate: false,
        minHeight: false, // string, '100px'
        maxHeight: false, // string, '100px'
        undoredo: false,
        shortcutsPopup: true,
        scrollTarget: window,
        mobile: 400,
        zIndex: 100,
        width: '600px',
        align: 'left', // center, right
        doctype: '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
        delimiters: false
    },
    autosave: {
        url: false,
        method: 'post'
    },
    image: {
        url: true,
        select: false,
        upload: false,
        name: 'file',
        data: false,
        drop: true,
        clipboard: true,
        multiple: 'single',
        types: ['image/*']
    },
    placeholders: {
        upload: '<svg height="20" viewBox="0 0 20 20" width="20" xmlns="http://www.w3.org/2000/svg"><path d="m17 20h-14c-1.65685425 0-3-1.3431458-3-3v-14c0-1.65685425 1.34314575-3 3-3h14c1.6568542 0 3 1.34314575 3 3v14c0 1.6568542-1.3431458 3-3 3zm1-16c0-1.1045695-.8954305-2-2-2h-12c-1.1045695 0-2 .8954305-2 2v8.524l5.32-5.324c.1671609-.20313009.41643233-.32082226.6795-.32082226s.5123391.11769217.6795.32082226l3.82 3.821 5.5-5.5v-1.521zm0 4.476-4.024 4.024 1.824 1.82c.2037074.2038286.2037074.5341714 0 .738l-.738.738c-.2038286.2037074-.5341714.2037074-.738 0l-6.324-6.32-6 6v.524c0 1.1045695.8954305 2 2 2h12c1.1045695 0 2-.8954305 2-2zm-7-2.976c0-.82842712.6715729-1.5 1.5-1.5s1.5.67157288 1.5 1.5-.6715729 1.5-1.5 1.5-1.5-.67157288-1.5-1.5z"/></svg>',
        image: '<svg height="180" viewBox="0 0 280 180" width="280" xmlns="http://www.w3.org/2000/svg"><path d="m278 0c1.104569 0 2 .8954305 2 2v176c0 1.104569-.895431 2-2 2h-276c-1.1045695 0-2-.895431-2-2v-176c0-1.1045695.8954305-2 2-2zm-1 3h-274v174h274zm-123 67c3.313708 0 6 2.6862915 6 6v28c0 3.313708-2.686292 6-6 6h-28c-3.313708 0-6-2.686292-6-6v-28c0-3.3137085 2.686292-6 6-6zm3 16-8.551 8.8727425 3.876 4.0130198c.432878.4494329.432878 1.1778247 0 1.6272577l-1.56825 1.627257c-.433136.449166-1.135114.449166-1.56825 0l-13.4385-13.9353211-12.75 13.2297351v1.155397c0 2.435527 1.90279 4.409912 4.25 4.409912h25.5c2.34721 0 4.25-1.974385 4.25-4.409912zm-4.25-13h-25.5c-2.34721 0-4.25 1.9569462-4.25 4.3709616v18.6290384l11.305-11.6354998c.355217-.4439369.884919-.7011509 1.443938-.7011509.559018 0 1.08872.257214 1.443937.7011509l8.1175 8.3507221 11.6875-12.0201444v-3.3241163h.002125c0-2.4140154-1.90279-4.3709616-4.25-4.3709616zm-7.75 5c1.656854 0 3 1.3431458 3 3s-1.343146 3-3 3-3-1.3431458-3-3 1.343146-3 3-3z"/></svg>',
        social: '<svg height="20" viewBox="0 0 20 20" width="20" xmlns="http://www.w3.org/2000/svg"><path d="m10 0c5.5228475 0 10 4.4771525 10 10s-4.4771525 10-10 10-10-4.4771525-10-10 4.4771525-10 10-10zm0 2c-4.418278 0-8 3.581722-8 8s3.581722 8 8 8 8-3.581722 8-8-3.581722-8-8-8zm0 6c1.1045695 0 2 .8954305 2 2s-.8954305 2-2 2-2-.8954305-2-2 .8954305-2 2-2z"/></svg>'
    },
    buffer: {
        limit: 50
    },
    toolbar: {
        sticky: true,
        stickyTopOffset: 0
    },
    buttons: {
        icons: false
    },
    colors: {
        base:   ['#111118', '#ffffff'],
        gray:   ['#212529', '#343a40', '#495057', '#868e96', '#adb5bd', '#ced4da', '#dee2e6', '#e9ecef', '#f1f3f5', '#f8f9fa'],
        red:    ["#c92a2a", "#e03131", "#f03e3e", "#fa5252", "#ff6b6b", "#ff8787", "#ffa8a8", "#ffc9c9", "#ffe3e3", "#fff5f5"],
        pink:   ["#a61e4d", "#c2255c", "#d6336c", "#e64980", "#f06595", "#f783ac", "#faa2c1", "#fcc2d7", "#ffdeeb", "#fff0f6"],
        grape:  ["#862e9c", "#9c36b5", "#ae3ec9", "#be4bdb", "#cc5de8", "#da77f2", "#e599f7", "#eebefa", "#f3d9fa", "#f8f0fc"],
        violet: ["#5f3dc4", "#6741d9", "#7048e8", "#7950f2", "#845ef7", "#9775fa", "#b197fc", "#d0bfff", "#e5dbff", "#f3f0ff"],
        indigo: ["#364fc7", "#3b5bdb", "#4263eb", "#4c6ef5", "#5c7cfa", "#748ffc", "#91a7ff", "#bac8ff", "#dbe4ff", "#edf2ff"],
        blue:   ["#1864ab", "#1971c2", "#1c7ed6", "#228be6", "#339af0", "#4dabf7", "#74c0fc", "#a5d8ff", "#d0ebff", "#e7f5ff"],
        cyan:   ["#0b7285", "#0c8599", "#1098ad", "#15aabf", "#22b8cf", "#3bc9db", "#66d9e8", "#99e9f2", "#c5f6fa", "#e3fafc"],
        teal:   ["#087f5b", "#099268", "#0ca678", "#12b886", "#20c997", "#38d9a9", "#63e6be", "#96f2d7", "#c3fae8", "#e6fcf5"],
        green:  ["#2b8a3e", "#2f9e44", "#37b24d", "#40c057", "#51cf66", "#69db7c", "#8ce99a", "#b2f2bb", "#d3f9d8", "#ebfbee"],
        lime:   ["#5c940d", "#66a80f", "#74b816", "#82c91e", "#94d82d", "#a9e34b", "#c0eb75", "#d8f5a2", "#e9fac8", "#f4fce3"],
        yellow: ["#e67700", "#f08c00", "#f59f00", "#fab005", "#fcc419", "#ffd43b", "#ffe066", "#ffec99", "#fff3bf", "#fff9db"],
        orange: ["#d9480f", "#e8590c", "#f76707", "#fd7e14", "#ff922b", "#ffa94d", "#ffc078", "#ffd8a8", "#ffe8cc", "#fff4e6"]
    },
    styles: {
        text: {
            'font-family': false,
            'font-size': '16px',
            'line-height': '1.5',
            'color': '#222228'
        },
        heading: {
            'font-family': false,
            'font-weight': 'bold',
            'color': '#111118'
        },
        link: {
            'color': '#0091ff',
            'font-weight': 'normal',
            'text-decoration': 'underline'
        },
        button: {
            'font-size': '18px',
            'font-weight': 'normal',
            'color': '#fff',
            'background-color': '#0091ff',
            'padding': '14px 40px',
            'border-radius': '24px'
        },
        code: {
            'padding': '10px',
            'font-family': 'monospace',
            'font-size': '14px',
            'line-height': '1.5',
            'background-color': '#f8f8f8',
            'color': '#111'
        },
        spacer: {
            'height': '10px'
        },
        divider: {
            'height': '2px',
            'background-color': '#111118'
        },
        table: {
            'padding': '10px 12px'
        }
    },
    headings: {
        h1: {
            'font-size': '32px',
            'line-height': '1.2'
        },
        h2: {
            'font-size': '28px',
            'line-height': '1.3'
        },
        h3: {
            'font-size': '20px',
            'line-height': '1.4'
        },
        h4: {
            'font-size': '16px',
            'line-height': '1.5'
        },
        h5: {
            'font-size': '16px',
            'line-height': '1.5'
        },
        h6: {
            'font-size': '16px',
            'line-height': '1.5'
        }
    },
    shortcutsBase: {
        'meta+z': '## shortcuts.meta-z ##',
        'meta+shift+z': '## shortcuts.meta-shift-z ##',
        'delete, backspace': '## shortcuts.delete ##'
    },
    shortcuts: {
        'ctrl+b, meta+b': {
            title: '## shortcuts.meta-b ##',
            name: 'meta+b',
            command: 'inline.format',
            params: { tag: 'b' }
        },
        'ctrl+i, meta+i': {
            title: '## shortcuts.meta-i ##',
            name: 'meta+i',
            command: 'inline.format',
            params: { tag: 'i' }
        },
        'ctrl+shift+d, meta+shift+d': {
            title: '## shortcuts.meta-shift-d ##',
            name: 'meta+shift+d',
            command: 'component.duplicate'
        },
        'ctrl+shift+up, meta+shift+up': {
            title: '## shortcuts.meta-shift-up ##',
            name: 'meta+shift+&uarr;',
            command: 'component.moveUp'
        },
        'ctrl+shift+down, meta+shift+down': {
            title: '## shortcuts.meta-shift-down ##',
            name: 'meta+shift+&darr;',
            command: 'component.moveDown'
        },
        'ctrl+shift+m, meta+shift+m': {
            title: '## shortcuts.meta-shift-m ##',
            name: 'meta+shift+m',
            command: 'inline.removeFormat'
        }
    },
    blocks: {
        add: false,
        hidden: false
    },
    forms: {
        textcolor: {
            'color': {
                type: 'color',
                picker: true
            }
        },
        linkcolor: {
            'link-color': {
                type: 'color',
                picker: true
            }
        },
        background: {
            'background-color': {
                type: 'color',
                picker: true
            }
        },
        backgroundimage: {
            'background-size': {
                type: 'checkbox',
                text: '## form.pattern ##'
            },
            'background-image': {
                type: 'upload',
                direct: true,
                observer: 'component.checkImageChange',
                upload: {
                    success: 'image.successBackground',
                    error: 'image.error',
                    remove: 'image.removeBackground'
                }
            }
        },
        alignment: {
            'align': {
                type: 'segment',
                label: '## form.alignment ##',
                segments: {
                    left: { name: 'align-left', prefix: 'align' },
                    center: { name: 'align-center', prefix: 'align' },
                    right: { name: 'align-right', prefix: 'align' }
                }
            },
            'valign': {
                type: 'segment',
                label: '## form.valign ##',
                observer: 'component.checkValign',
                segments: {
                    none: { name: 'valign-none', prefix: 'valign' },
                    top: { name: 'valign-top', prefix: 'valign' },
                    middle: { name: 'valign-middle', prefix: 'valign' },
                    bottom: { name: 'valign-bottom', prefix: 'valign' }
                }
            }
        },
        border: {
            'border-width': {
                type: 'number',
                label: '## form.width ##'
            },
            'border-color': {
                type: 'color',
                label: '## form.color ##'
            },
            'border-radius': {
                type: 'number',
                label: '## form.radius ##'
            }
        }
    },

    // private
    containers: {
        main: ['toolbar', 'editor', 'source']
    },
    markerChar: '\ufeff',
    tags: {
        denied: ['font', 'html', 'style', 'script', 'head', 'link', 'title', 'body', 'meta', 'applet', 'marquee'],
        inline: ['a', 'span', 'strong', 'strike', 'b', 'u', 'em', 'i', 'code', 'del', 'ins', 'samp', 'kbd', 'sup', 'sub', 'mark', 'var', 'cite', 'small', 'abbr'],
        block: ['pre', 'ul', 'ol', 'li', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',  'dl', 'dt', 'dd', 'div', 'table', 'tbody', 'thead', 'tfoot', 'tr', 'th', 'td', 'blockquote', 'output', 'figcaption', 'figure', 'address', 'main', 'section', 'header', 'footer', 'aside', 'article', 'iframe']
    },
    _blocks: {},
    _styles: '#outlook a{padding:0}.ExternalClass{width:100%}.ExternalClass,.ExternalClass p,.ExternalClass span,.ExternalClass font,.ExternalClass td,.ExternalClass div{line-height:100%}body,table,td,a{-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%}table,td{mso-table-lspace:0;mso-table-rspace:0}img{-ms-interpolation-mode:bicubic}img{border:0;outline:none;text-decoration:none}a img{border:none}td img{vertical-align:top}table,table td{border-collapse:collapse}body{margin:0;padding:0;width:100% !important}.mobile-spacer{width:0;display:none}@media all and (max-width:639px){.container{width:100% !important;max-width:600px !important}.mobile{width:auto !important;max-width:100% !important;display:block !important}.mobile-center{text-align:center !important}.mobile-right{text-align:right !important}.mobile-left{text-align:left!important;}.mobile-hidden{max-height:0;display:none !important;mso-hide:all;overflow:hidden}.mobile-spacer{width:auto !important;display:table !important}.mobile-image,.mobile-image img {height: auto !important; max-width: 600px !important; width: 100% !important}}',
    _msoStyles: '<!--[if mso]><style type="text/css">body, table, td, a { font-family: Arial, Helvetica, sans-serif !important; }</style><![endif]-->',
    _tags: [
        'html',
        'head',
        'title',
        'font',
        'style',
        'body',
        'preheader',
        'main',
        'header',
        'container',
        'footer',
        'block',
        'spacer',
        'divider',
        'text',
        'link',
        'list',
        'list-item',
        'heading',
        'grid',
        'column',
        'column-spacer',
        'image',
        'menu',
        'menu-item',
        'menu-spacer',
        'social',
        'social-item',
        'social-spacer',
        'button',
        'table',
        'table-head',
        'table-body',
        'table-row',
        'table-cell',
        'code',
        'mobile-spacer',
        'mobile-divider',
        'var'
    ],
    _nested: [
        'head',
        'body',
        'main',
        'header',
        'container',
        'footer',
        'block',
        'grid',
        'column',
        'menu',
        'social',
        'table',
        'table-head',
        'table-body',
        'table-row',
        'list'
    ],
    _elements: [
        'main',
        'header',
        'footer',
        'block',
        'grid',
        'column',
        'spacer',
        'divider',
        'image',
        'text',
        'heading',
        'link',
        'button',
        'menu',
        'social',
        'table-cell',
        'list'
    ],
    _blockElements: [
        'column',
        'spacer',
        'divider',
        'image',
        'text',
        'heading',
        'link',
        'button',
        'menu',
        'social',
        'list'
    ]
};
Revolvapp.lang.en = {
    "accessibility": {
        "help-label": "Rich email editor"
    },
    "editor": {
        "title": "Body",
        "blocks": "Blocks",
        "add-block": "Add Block"
    },
    "placeholders": {
        "type-url-to-add-link": "Type url to add a link...",
        "paste-url-of-image": "Paste url of image...",
        "or-drag-and-drop-the-image": "or drag and drop the image:",
        "lorem": "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        "lorem-short": "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "lorem-heading": "Lorem ipsum dolor sit amet...",
        "button": "Button",
        "link": "Link...",
        "item": "Item"
    },
    "buttons": {
        "add-item": "Add Item",
        "cancel": "Cancel",
        "insert": "Insert",
        "unlink": "Unlink",
        "save": "Save",
        "add": "Add",
        "html": "HTML",
        "shortcuts": "Shortcuts",
        "mobile-view": "Mobile View",
        "background": "Background",
        "settings": "Settings",
        "alignment": "Alignment",
        "text-color": "Text Color",
        "border": "Border",
        "link": "Link",
        "items": "Items",
        "image": "Image"
    },
    "add-sections": {
        "one": "One",
        "two": "Two",
        "three": "Three",
        "misc": "Misc"
    },
    "shortcuts": {
        "delete": "Delete",
        "meta-z": "Undo",
        "meta-shift-z": "Redo",
        "meta-b": "Bold",
        "meta-i": "Italic",
        "meta-shift-m": "Remove inline format",
        "meta-shift-d": "Duplicate",
        "meta-shift-up": "Move up",
        "meta-shift-down": "Move down"
    },
    "blocks": {
        "text": "Text",
        "heading": "Heading",
        "image": "Image",
        "image-text": "Image with text",
        "image-heading-text": "Image with heading & text",
        "button": "Button",
        "link": "Link",
        "divider": "Divider",
        "spacer": "Spacer",
        "social": "Social",
        "list": "List",
        "menu": "Menu",
        "heading-text": "Heading & text",
        "two-text": "Text",
        "two-headings-text": "Headings & text",
        "two-images": "Images",
        "two-images-text": "Images with text",
        "two-images-headings-text": "Images with headings & text",
        "two-buttons": "Buttons",
        "two-links": "Links",
        "three-text": "Text",
        "three-headings-text": "Headings & text",
        "three-images": "Images",
        "three-images-text": "Images with text",
        "three-images-headings-text": "Images with headings & text",
        "misc-heading-text": "Heading & text",
        "misc-text-heading": "Text & heading",
        "misc-image-text": "Image with text",
        "misc-text-image": "Text with image",
        "misc-image-heading-text": "Image with heading & text",
        "misc-heading-text-image": "Heading & text with image"
    },
    "headings": {
        "heading-1": "Heading 1",
        "heading-2": "Heading 2",
        "heading-3": "Heading 3",
        "heading-4": "Heading 4",
        "heading-5": "Heading 5",
        "heading-6": "Heading 6"
    },
    "lists": {
        "unordered": "Unordered",
        "ordered": "Ordered"
    },
    "elements": {
       "block": "Block",
       "body": "Body",
       "button": "Button",
       "column": "Column",
       "grid": "Grid",
       "divider": "Divider",
       "footer": "Footer",
       "header": "Header",
       "heading": "Heading",
       "image": "Image",
       "link": "Link",
       "main": "Main",
       "menu": "Menu",
       "social": "Social",
       "spacer": "Spacer",
       "text": "Text",
       "table-cell": "Cell",
       "list": "List"
    },
    "popup": {
        "back": "Back",
        "insert-link": "Insert Link",
        "edit-link": "Edit Link",
        "add-item": "Add Item",
        "edit-item": "Edit Item",
        "pick-color": "Pick a color",
        "edit-divider": "Edit Divider",
        "edit-column": "Edit Column",
        "border": "Border",
        "items": "Items",
        "background": "Background",
        "background-image": "Image",
        "text-color": "Text Color",
        "link-color": "Link Color",
        "settings": "Settings"
    },
    "form": {
        "list-type": "List type",
        "link": "Link",
        "url": "Url",
        "text": "Text",
        "name": "Name",
        "alt-text": "Alt Text",
        "alignment": "Alignment",
        "valign": "Valign",
        "width": "Width",
        "color": "Color",
        "radius": "Radius",
        "image-width": "Image Width",
        "padding": "Padding",
        "margin": "Margin",
        "column-space": "Column Space",
        "height": "Height",
        "text-size": "Text Size",
        "pattern": "Pattern",
        "image": "Image",
        "upload": "Upload",
        "bold": "Bold",
        "underline": "Underline",
        "spacer-content": "Spacer Content",
        "heading-level": "Heading Level",
        "responsive-on-mobile": "Responsive on mobile"
    }
};
var App = function($element, settings) {
    // environment
    this.keycodes = Revolvapp.keycodes;
    this.dom = Revolvapp.dom;
    this.ajax = Revolvapp.ajax;
    this.prefix = Revolvapp.prefix;
    this.uuid = 0;
    this.$win = this.dom(window);
    this.$doc = this.dom(document);
    this.$body = this.dom('body');
    this.$element = $element;
    this._elementContent = $element.html();
    this._store = Revolvapp._store;
    this._subscribe = Revolvapp._subscribe;
    this.app = this;

    // initial
    this.initialSettings = settings;

    // starter
    this._initer = ['setting', 'lang'];
    this._priority = ['utils', 'container', 'source', 'toolbar', 'path', 'control', 'popup', 'editor', 'accessibility'];
    this._plugins = [];

    // started
    this.started = false;

    // start
    this.start();
};

App.prototype = {
    // start
    start: function(settings) {
        if (this.isStarted()) return;
        if (settings) this.initialSettings = settings;

        // core
        this._initCore();
        this._plugins = this.setting.get('plugins');

        // starting
        this.broadcast('app.before.start');

        // init
        this._initModules();
        this._initPlugins();

        // start
        this._startPriority();
        this._startModules();
        this._startPlugins();

        this.started = true;

        // started
        this.broadcast('app.start');
    },
    isStarted: function() {
        return this.started;
    },

    // stop
    stop: function() {
        if (this.isStopped()) return;

        // stopping
        this.broadcast('app.before.stop');

        this._stopPriority();
        this._stopModules();
        this._stopPlugins();

        this.started = false;

        // stopped
        this.broadcast('app.stop');
    },
    isStopped: function() {
        return !this.started;
    },

    // destroy
    destroy: function() {
        this.stop();
        this.broadcast('app.destroy');
        this.$element.dataset($RE.namespace, false);
    },

    // broadcast
    broadcast: function(name, params) {
        var event = (params instanceof App.Event) ? params : new App.Event(name, params);
        if (typeof this._subscribe[name] !== 'undefined') {
            var events = this._subscribe[name];
            for (var i = 0; i < events.length; i++) {
                var instance = this[events[i].module];
                if (instance) {
                    events[i].func.call(instance, event);
                }
            }
        }

        // callbacks
        var callbacks = (this.setting.has('subscribe')) ? this.setting.get('subscribe') : {};
        if (typeof callbacks[name] === 'function') {
            callbacks[name].call(this, event);
        }

        return event;
    },

    // create
    create: function(name) {
        if (typeof this._store[name] === 'undefined') {
            Revolvapp.error('The class "' + name + '" does not exist.');
        }

        var args = [].slice.call(arguments, 1);
        var instance = new this._store[name].proto();

        instance.app = this;
        instance.dom = this.dom;
        instance.ajax = this.ajax;
        instance.prefix = this.prefix;
        instance.uuid = this.uuid;

        if (this.lang) instance.lang = this.lang;
        if (this.setting) instance.opts = this.setting.dump();

        if (instance.init) {
            var res = instance.init.apply(instance, args);
            instance = (res) ? res : instance;
        }

        return instance;
    },

    // api
    api: function(name) {
        var args = [].slice.call(arguments, 1);

        var namespaces = name.split(".");
        var func = namespaces.pop();
        var context = this;
        for (var i = 0; i < namespaces.length; i++) {
            context = context[namespaces[i]];
        }

        if (context && typeof context[func] === 'function') {
            return context[func].apply(context, args);
        }
    },

    // init
    _initCore: function() {
        for (var i = 0; i < this._initer.length; i++) {
            this[this._initer[i]] = this.create(this._initer[i]);
        }
    },
    _initModules: function() {
        for (var key in this._store) {
            if (this._store[key].type === 'module' && this._initer.indexOf(key) === -1) {
                this[key] = this.create(key);
            }
        }
    },
    _initPlugins: function() {
        var plugins = this.setting.get('plugins');
        for (var key in this._store) {
            if (this._store[key].type === 'plugin' && plugins.indexOf(key) !== -1) {
                this[key] = this.create(key);
            }
        }
    },

    // start
    _startPriority: function() {
        for (var i = 0; i < this._priority.length; i++) {
            this._call(this[this._priority[i]], 'start');
        }
    },
    _startModules: function() {
        this._iterate('module', 'start');
    },
    _startPlugins: function() {
        this._iterate('plugin', 'start');
    },

    // stop
    _stopPriority: function() {
        var priority = this._priority.slice().reverse();
        for (var i = 0; i < priority.length; i++) {
            this._call(this[priority[i]], 'stop');
        }
    },
    _stopModules: function() {
        this._iterate('module', 'stop');
    },
    _stopPlugins: function() {
        this._iterate('plugin', 'stop');
    },

    // iterate
    _iterate: function(type, method) {
        for (var key in this._store) {
            if (this._store.hasOwnProperty(key)) {
                var isIn = (type === 'module') ? (this._priority.indexOf(key) === -1) : (this._plugins.indexOf(key) !== -1);
                if (this._store[key].type === type && isIn) {
                    this._call(this[key], method);
                }
            }
        }
    },

    // call
    _call: function(instance, method) {
        if (typeof instance[method] === 'function') {
            instance[method].apply(instance);
        }
    }
};
App.Event = function(name, params) {
    // local
    this.name = name;
    this.params = (typeof params === 'undefined') ? {} : params;
    this.stopped = false;
};

App.Event.prototype = {
    is: function(name) {
        return this.get(name);
    },
    has: function(name) {
        return (typeof this.params[name] !== 'undefined');
    },
    get: function(name) {
        return this.params[name];
    },
    set: function(name, value) {
        this.params[name] = value;
    },
    stop: function() {
        this.stopped = true;
    },
    isStopped: function() {
        return this.stopped;
    }
};
Revolvapp.add('mixin', 'block', {
    init: function() {
        // build
        this.build();
    },
    getSource: function() {
        return this.block.getSource();
    },
    getElement: function() {
        return this.block.getElement();
    }
});
Revolvapp.add('mixin', 'tag', {
    init: function(source, element, body) {
        // source
        this.$source = this._createSource(source);

        // build source props
        this._buildSourceProps(source);

        // build data & params
        this.data = {};
        if (this.build) this.build();
        this._buildDataFromSource();

        // element
        if (element) {
            this.$element = this._createFromElement(element);
        }
        else {
            this.create();
        }

        // target
        this.$target = this.render();

        // render
        this._renderData();
        this._renderStyle();
        this._renderElement();
    },

    // build
    _buildSourceProps: function(source) {
        var data = (source && typeof source !== 'string' && !source.get) ? source : {};
        for (var name in data) {
            if (name === 'html') {
                this.$source.html(data[name]);
            }
            else {
                this.$source.attr(name, data[name]);
            }
        }
    },
    _buildDataFromSource: function() {
        for (var name in this.data) {
            var value = (name === 'html') ? this.$source.html() : this.$source.attr(name);
            var prop = this.data[name].prop || null;
            if (value !== null) {
                this.data[name].value = value;
            }
            else if (prop !== null) {
                this.data[name].value = prop;
            }
        }
    },

    // create
    _createFromElement: function(element) {
        var $el = element;
        this.$table = $el.find('table').first();
        this.$row = $el.find('tr').first();
        this.$cell = $el.find('td').first();

        return $el;
    },
    _createSource: function(source) {
        var $source;
        if (typeof source === 'string' || (source && source.get)) {
            $source = this.dom(source);
        }
        else  {
            $source = this.dom('<re-' + this.type + '></re-' + this.type + '>');
        }

        return $source;
    },
    _createTableContainer: function(width) {
        this.$table = this._createTable(width);
        this.$row = this._createRow();
        this.$cell = this._createCell();

        // append
        this.$row.append(this.$cell);
        this.$table.append(this.$row);

        return this.$table;
    },
    _createTable: function(width) {
        var $table = this.dom('<table>').attr({ 'cellpadding': 0, 'cellspacing': 0, 'border': 0 });

        if (width) {
            $table.attr('width', (width === 'auto') ? width : this.app.normalize.number(width));
            $table.css('width', width);
        }

        return $table;
    },
    _createCell: function() {
        var $cell = this.dom('<td>');
        $cell.attr({ 'align': this._getSourceAlign(), 'valign': 'top' });
        $cell.css({ 'vertical-align': 'top', 'line-height': 1 });

        return $cell;
    },
    _createRow: function() {
        return this.dom('<tr>');
    },
    _createImage: function() {
        return this.dom('<img>').attr('border', 0).css({ 'margin': '0', 'padding': 0, 'max-width': '100%', 'border': 'none', 'vertical-align': 'top' });
    },
    _createLink: function() {
        var $link = this.dom('<a>');

        $link.attr({ 'href': '#', 'target': '_blank' });
        $link.css({
            'font-family': this.getStyle('text', 'font-family'),
            'font-size': this.getStyle('text', 'font-size'),
            'font-weight': this.getStyle('link', 'font-weight'),
            'color': this.getStyle('link', 'color'),
            'text-decoration': 'underline'
        });

        return $link;
    },

    // render
    _render: function(name, value, setter) {
        var targets = this.getDataTargets(name);
        var isRemove = (name === 'level') ? false : this._setIsRemove(name, value);

        // setter
        if (setter) {
            this[setter].call(this, value);
            if (isRemove) {
                this._removeValue(name);
            }
            return;
        }

        // set
        for (var i = 0; i < targets.length; i++) {
            this._set(targets[i], name, value);
        }

        // source
        if (isRemove) {
            this._removeValue(name);
        }
        else {
            if (name === 'html') this.$source.html(value);
            else this.$source.attr(name, value);
        }
    },
    _renderData: function() {
        for (var name in this.data) {
            var value = (this.data[name].value) ? this.data[name].value : undefined;
            if (value === undefined) continue;

            value = this.app.normalize.setter(name, value);
            value = this.app.content.replaceToHttps(name, value);

            this._render(name, value, this.data[name].setter);
        }
    },
    _renderStyle: function() {
        var style = this.$source.attr('style');
        if (!style) return;

        var data = this._cssToObject(style);
        this._renderDataStyle(data);
    },
    _renderDataStyle: function(data) {
        for (var name in data) {
            if (this.data[name]) {
                this._render(name, data[name], this.data[name].setter);
            }
            else {
                this.$element.css(name, data[name]);
                continue;
            }
        }
    },
    _renderElement: function() {
        // instance & type
        this.$element.dataset('instance', this);
        this.$element.attr('data-' + this.prefix + '-type', this.type);

        this._renderNoneditable();
        this._renderEditable();
    },
    _renderNoneditable: function() {
        if (this.$source.attr('noneditable')) {
            this.$element.attr('noneditable', true);
        }
    },
    _renderEditable: function() {
        if (!this.isEditable() || this.opts.editor.viewOnly) return;
        if (this.$source.closest('[noneditable]').length !== 0) return;

        if (!this.opts.editor.grammarly) {
            this.$element.find('.' + this.prefix + '-editable').attr('data-gramm_editor', false);
        }

        this.getEditableElement().attr('contenteditable', true);
    },

    // css
    _cssToObject: function(str) {
        var regex = /([\w-]*)\s*:\s*([^;]*)/g;
        var match, props = {};
        do {
            match = regex.exec(str);
            if (match != null) {
                props[match[1]] = match[2].trim();
            }
        }
        while (match);

        return props;
    },

    // remove
    _removeValue: function(name) {
        if (name === 'html') this.$source.html('');
        else this.$source.removeAttr(name);
    },

    // get
    _get: function(name, getter) {
        var value;

        if (getter) {
            value = this[getter].call(this);
        }
        else {
            value = (name === 'html') ? this.$source.html() : this.$source.attr(name);
            if (value === null && this.data[name].prop) {
                value = this.data[name].prop;
            }
        }

        // normalize
        value = this.app.normalize.getter(name, value);

        return value;
    },
    _getSibling: function(method) {
        var node = this.getElement().get();
        var sibling = this.dom();
        do {
            node = node[method];
            if (node && getComputedStyle(node, null).display !== 'none') {
                sibling = node;
                break;
            }
        }
        while (node);

        var $el = this.dom(sibling);
        var instance = false;
        var type = $el.attr('data-' + this.prefix + '-type');
        if (type) {
            instance = $el.dataget('instance');
        }

        return instance;
    },
    _getSourceAlign: function() {
        return (this.$source.attr('align')) ? this.$source.attr('align') : this.opts.editor.align;
    },
    _getSourceWidth: function() {
        return (this.$source.attr('width')) ? this.$source.attr('width') : this.opts.editor.width;
    },
    _getSourceHtml: function() {
        return this.$source.html().trim();
    },

    // set
    _set: function($target, name, value) {
        var tag = $target.get().tagName.toLowerCase();
        switch (name) {
            case 'html':
                $target.html(value);
                break;
            case 'color':
            case 'padding':
            case 'margin':
            case 'width':
            case 'height':
            case 'border':
            case 'font-size':
            case 'font-weight':
            case 'font-style':
            case 'line-height':
            case 'box-shadow':
            case 'max-width':
            case 'max-height':
            case 'letter-spacing':
            case 'text-transform':
            case 'text-decoration':
            case 'background-size':
                $target.css(name, value);
                if (value === 'cover') {
                    $target.css('background-position', 'center');
                }
                else {
                    $target.css('background-position', '');
                }
                break;
            case 'background-image':
                $target.attr('background', value);
                $target.css(name, 'url("' + value + '")');
                break;
            case 'border-radius':
                $target.css(name, value);
                if (tag !== 'img' && value !== 0) {
                    $target.closest('table').css('border-collapse', 'separate');
                }
                break;
            case 'background-color':
                $target.css(name, value);
                if (tag === 'td' || tag === 'th') {
                    if (value === null) $target.removeAttr('bgcolor');
                    else $target.attr('bgcolor', value);
                }
                break;
            case 'class':
                $target.addClass(value);
                break;
            case 'alt':
            case 'href':
            case 'align':
            case 'colspan':
            case 'rowspan':
                $target.attr(name, value);
                break;
            case 'valign':
                if (value === 'none') {
                    $target.css('vertical-align', '');
                    if (tag === 'td') {
                        $target.removeAttr('valign');
                    }
                }
                else {
                    $target.css('vertical-align', value);
                    if (tag === 'td') {
                        $target.attr('valign', value);
                    }
                }
                break;
        }
    },
    _setIsRemove: function(name, value) {
        var remove = false;
        var defaultValue = this.getDataDefault(name);
        if (value === defaultValue) {
            return true;
        }

        switch (name) {
            case 'alt':
            case 'color':
            case 'href':
            case 'border':
            case 'font-weight':
            case 'border-radius':
            case 'background-color':
                remove = (value === '');
                break;
            case 'background-image':
                remove = (value === false);
                break;
            case 'background-size':
                remove = (value === 'auto');
                break;
            case 'valign':
                remove = (value === 'none');
                break;
            case 'font-style':
                remove = (value === 'normal');
                break;
            case 'margin':
                remove = (value === 0);
                break;
        }

        return remove;
    },
    _setParse: function(data) {
        var res = {};
        for (var name in data) {

            // border
            if (name === 'border-width' || name === 'border-color') {
                res['border'] = parseInt(data['border-width']) + 'px solid ' + data['border-color'];
            }
            else {
                res[name] = data[name];
            }
        }

        return res;
    },

    // parse
    _parseHtmlLinks: function($source, $target, instance) {
        var html = $target.html();
        html = this.app.content.parseHtmlLinks($source, html, instance);
        $target.html(html);
    },


    // get
    getStyle: function(section, name) {
        var o = this.opts.styles;
        if (typeof o[section] !== 'undefined' && typeof o[section][name] != 'undefined') {
            var value = o[section][name];
            return (name === 'font-family') ? (value || this.opts.editor.font) : value;
        }
    },
    getTag: function() {
        return this.$element.get().tagName.toLowerCase();
    },
    getOffset: function() {
        var offset = this.app.editor.getFrame().offset();
        var elOffset = this.$element.offset();

        return { top: offset.top + elOffset.top, left: offset.left + elOffset.left }
    },
    getDimension: function() {
        return {
            width: this.$element.width(),
            height: this.$element.height()
        };
    },
    getParent: function(type) {
        var types = (type === 'layer') ? ['main', 'header', 'footer'] : [type];
        var $el = this.getElement();
        var $parent = this.app.element.getParents($el, types).first();

        return ($parent.length !== 0) ? $parent.dataget('instance') : false;
    },
    getNext: function() {
        return this._getSibling('nextElementSibling');
    },
    getPrev: function() {
        return this._getSibling('previousElementSibling');
    },
    getElements: function(types, except, column) {
        types = types || this.opts._blockElements;

        var elms = this.app.element.getChildren(this.$element, types);
        if (except) {
            elms = elms.not(this.app.element.getTypesSelector(except));
        }

        if (column) {
            elms = elms.filter(function($node) {
                return ($node.closest('[data-' + this.prefix + '-type=column]').length === 0)
            }.bind(this));
        }

        return elms
    },
    getElement: function() {
        return this.$element;
    },
    getEditableElement: function() {
        var $child = this.$element.find('.' + this.prefix + '-editable').first();
        var $target = ($child.length !== 0) ? $child : this.$element;

        return $target;
    },
    getSource: function() {
        return this.$source;
    },
    getSourceStyle: function() {
        return this.$source.attr('stylename');
    },
    getTarget: function() {
        return this.$target;
    },
    getTitle: function() {
        return '## elements.' + this.getType() + ' ##';
    },
    getType: function() {
        return this.type;
    },
    getLinkData: function($source) {

        $source = $source || this.$source;

        var color = (this.isType('text')) ? this.getLinkColor() : false;
        color = color || this.getStyle('link', 'color');

        if (this.data['link-color']) {
            this.data['link-color'].value = color;
        }

        return {
            'font-family': $source.attr('font-family') || this.getStyle('text', 'font-family'),
            'font-size': $source.attr('font-size') || this.getStyle('text', 'font-size'),
            'font-weight': this.getStyle('link', 'font-weight'),
            'line-height': $source.attr('line-height') || this.getStyle('text', 'line-height'),
            'color': color,
            'text-decoration': this.getStyle('link', 'text-decoration') || 'underline'
        };
    },
    getData: function(name) {
        var data = {};
        for (var key in this.data) {

            data[key] = this._get(key, this.data[key].getter);

            // parse
            if (key === 'border') {
                var value = data[key];
                if (value) {
                    var arr = value.split(' ');
                    data['border-width'] = this.app.normalize.getter('border-width', arr[0]);
                    data['border-color'] = this.app.normalize.getter('border-color', arr[2]);
                }
            }
        }

        return (name) ? data[name] : data;
    },
    getDataTargets: function(name) {
        var target = (this.data[name]) ? this.data[name].target : false;
        if (target === false) {
            return target;
        }
        else {
            var targets = [];
            for (var i = 0; i < target.length; i++) {
                targets.push(this.getDataTarget(target[i]));
            }

            return targets;
        }
    },
    getDataTarget: function(name) {
        return this['$' + name];
    },
    getDataDefault: function(name) {
        var val = null;
        if (typeof this.data[name] !== 'undefined' && typeof this.data[name].prop  !== 'undefined') {
            val = this.data[name].prop;
        }

        return val;
    },
    getAlign: function() {
        var block = this.getParent('block');
        var column = this.getParent('column');
        var value = this.$source.attr('align');
        if (value === null) {
            if (column) value = column.getSource().attr('align');
            else if (block) value = block.getSource().attr('align');
        }

        if (value === null && this.opts.direction === 'rtl') {
            value = 'right';
        }

        return value;
    },
    getHeadingStyleByLevel: function(type, name) {
        return (typeof this.opts.headings[type] !== 'undefined') ? this.opts.headings[type][name] : this.opts.styles.text[name];
    },
    getElementsTextColor: function() {
        var $el = this.getElements(['text', 'heading']).first();
        var color = ($el.length !== 0) ? $el.dataget('instance').getData('color') : null;

        return (color !== null) ? color : this.getStyle('text', 'color');

    },
    getElementsLinkColor: function() {
        var $el = this.getElements(['text']).find('a').first();
        var color = ($el.length !== 0) ? $el.css('color') : null;

        return (color !== null) ? this.app.color.normalize(color) : this.getStyle('link', 'color');
    },

    // set
    setData: function(data) {
        data = this._setParse(data);

        for (var name in data) {
            var value = data[name];
            var setter = (this.data[name]) ? this.data[name].setter : false;

            value = this.app.normalize.setter(name, value);
            value = this.app.content.replaceToHttps(name, value);

            this._render(name, value, setter);
        }
    },
    setStyle: function(data) {
        this._renderDataStyle(data);
    },
    setElementsTextColor: function(value) {
        this.getElements(['text', 'heading']).each(function($node) {
            $node.dataget('instance').setData({ 'color': value });
        });
    },
    setElementsLinkColor: function(value) {
        this.getElements(['text']).find('a').css('color', value);
    },

    // is
    isActiveSource: function() {
        return this.$source.attr('active');
    },
    isAllowedButton: function(obj) {
        var type = this.getType();

        // except
        if (Object.prototype.hasOwnProperty.call(obj, 'except') && obj.except.indexOf(type) !== -1) {
            return false;
        }

        // all
        if (typeof obj.components === 'undefined' || obj.components === 'all') {
            return true;
        }
        // array of element
        else if ((Array.isArray(obj.components) && obj.components.indexOf(type) !== -1)) {
            return true;
        }
        else if (obj.components === 'editable' && this.isEditable()) {
            return true;
        }

        return false;
    },
    isEditable: function() {
        return this.editable;
    },
    isType: function(type) {
        return (type === this.type);
    },
    isBlock: function() {
        return this.isType('block');
    },
    isLayer: function() {
        return (this.isType('main') || this.isType('header') || this.isType('footer'));
    },
    isEmpty: function() {
        return (this.getElements().length === 0);
    },
    isUnremovable: function() {
        return this.$source.attr('unremovable');
    },

    // render
    renderNodes: function() {
        var tag = this.$source.get().tagName.toLowerCase().replace('re-', '');
        if (this.opts._nested.indexOf(tag) !== -1) {
            this.app.editor.render(this.$source.children(), this.getTarget());
        }
    },

    // remove
    remove: function() {
        // image remove events
        if (this.isType('image')) {
            this.app.broadcast('image.remove', { image: this.$img });
        }
        else {
            this.$element.find('[data-' + this.prefix + '-type=image]').each(function($node) {
                this.app.broadcast('image.remove', { image: $node });
            }.bind(this));
        }

        // remove
        this.app.broadcast('component.remove', { element: this.$element });
        this.$source.remove();
        this.$element.remove();
    },
    removeStyle: function(data) {
        for (var name in data) {
            data[name] = this.getDataDefault(name);
        }

        this._renderDataStyle(data);
    },

    add: function(instance) {
        this.getTarget().append(instance.getElement());
        this.getSource().append(instance.getSource());
    },
    sync: function() {
        var html = this.getTarget().html().trim();
        html = this.app.utils.wrap(html, function($w) {
            $w.find('a').removeAttr('style target');
        });

        if (this.getType() === 'list') {
            html = this.app.utils.wrap(html, function($w) {
                $w.find('li').replaceWith(function(node) {
                    var classname = node.getAttribute('class');
                    var $item = this.dom('<re-list-item>').html(node.innerHTML);
                    if (classname) $item.addClass(classname);

                    return $item;
                }.bind(this));
            }.bind(this));
        }

        if (this.getType() === 'heading' && this.href === true) {
            html = this.$link.html().trim();
        }

        this.$source.html(html);
    }
});
Revolvapp.add('mixin', 'tool', {
    init: function(name, obj, popup, data) {
        this.name = name;
        this.setter = popup.get('setter');
        this.popup = popup;
        this.data = data;
        this.instance = popup.getInstance();
        this.obj = this._observe(obj);

        if (this.obj) {
            this._build();
        }
    },
    getElement: function() {
        return this.$tool;
    },
    getInput: function() {
        return this.$input;
    },
    getValue: function() {
        var value = this.$input.val();
        return value.trim();
    },
    setValue: function(value) {
        this.$input.val(value);
    },
    setFocus: function() {
        this.$input.focus();
    },
    trigger: function(value) {
        this.setValue(value);

        if (this.setter) {
            this.app.api(this.setter, this.popup);
        }
    },

    // private
    _build: function() {
        this._buildTool();
        this._buildLabel();
        this._buildInputElement();
        this._buildInput();
        this._buildEvent();

        // props
        if (this._has('placeholder')) this.$input.attr('placeholder', this.lang.parse(this.obj.placeholder));
        if (this._has('width')) this.$input.css('width', this.obj.width);
        if (this._has('classname')) this.$input.addClass(this.obj.classname);
    },
    _buildInputElement: function() {
        this.$input = this.dom('<' + this._getInputParam('tag') + '>').addClass(this.prefix + this._getInputParam('classname'));
        this.$input.attr({ 'name': this.name, 'type': this._getInputParam('type'), 'data-type': this.type });
        this.$input.dataset('instance', this);
    },
    _buildInput: function() {
        return;
    },
    _buildEvent: function() {
        var types = ['segment'];
        if (types.indexOf(this.type) === -1 && this.setter) {
            var events = (this.type === 'checkbox' || this.type === 'select') ? 'change' : 'input';
            events = (this.type === 'number') ? events + ' change' : events;

            this.$input.on(events, this._catchSetter.bind(this));
        }
    },
    _buildTool: function() {
        this.$tool = this.dom('<div>').addClass(this.prefix + '-form-item').dataset('instance', this);
    },
    _buildLabel: function() {
        if (this.type !== 'checkbox' && this._has('label')) {
            this.$label = this.dom('<label>').addClass(this.prefix + '-form-label').html(this.lang.parse(this.obj.label));
            this.$tool.append(this.$label);
        }
    },
    _getInputParam: function(name) {
        return (this.input && typeof this.input[name] !== 'undefined') ? this.input[name] : '';
    },
    _get: function(name) {
        return this.obj[name];
    },
    _has: function(name) {
        return Object.prototype.hasOwnProperty.call(this.obj, name);
    },
    _observe: function(obj) {
        if (Object.prototype.hasOwnProperty.call(obj, 'observer')) {
            obj = this.app.api(obj.observer, obj, this.name);
        }

        return obj;
    },
    _catchSetter: function(e) {
        if (e.type === 'keydown' && e.which !== 13) return;
        if (e.type === 'keydown') e.preventDefault();

        // call setter
        this.app.api(this.setter, this.popup);
    }
});
Revolvapp.add('module', 'accessibility', {
    start: function() {
        this._buildRole();
        this._buildLabel();
    },
    _buildRole: function() {
        this.app.editor.getEditor().attr({ 'aria-labelledby': this.prefix + '-voice', 'role': 'presentation' });
    },
    _buildLabel: function() {
        var html = this.lang.get('accessibility.help-label');
        var $label = this._createLabel(html);

        // append
        this.app.container.get('main').prepend($label);
    },
    _createLabel: function(html) {
        var $label = this.dom('<span />').addClass(this.prefix + '-voice-label');
        $label.attr({ 'id': this.prefix + '-voice-' + this.uuid, 'aria-hidden': false });
        $label.html(html);

        return $label;
    }
});
Revolvapp.add('module', 'button', {
    init: function(name, obj, $container, type) {
        // build
        if (typeof name === 'object') {
            this.name = name.name;
            this.obj = obj;
            this._buildFromElement(name.element);
        }
        else if (name) {
            this.type = type || false;
            this.name = name;

            var res = this._observe(obj);
            this.obj = (typeof res === 'undefined') ? obj : res;

            if (this.obj) {
                this._build(name, $container);
            }
        }
    },
    setColor: function(stack, data) {
        var name = stack.getName();
        if (name === 'background' || name === 'text-color') {
            var key = (name === 'background') ? 'background-color' : 'color';
            this.setBackground(data[key]);
        }
    },
    isButton: function() {
        return true;
    },
    isAddbar: function() {
        return this._has('addbar');
    },
    isControl: function() {
        return this._has('control');
    },
    getName: function() {
        return this.name;
    },
    getTitle: function() {
        return this.title;
    },
    getParams: function() {
        return (this._has('params')) ? this.obj.params : false;
    },
    getOffset: function() {
        return this.$button.offset();
    },
    getDimension: function() {
        return {
            width: this.$button.width(),
            height: this.$button.height()
        };
    },
    getElement: function() {
        return this.$button;
    },
    setBackground: function(color) {
        this._background('add', color);
    },
    resetBackground: function() {
        this._background('remove', '');
    },

    // private
    _has: function(name) {
        return Object.prototype.hasOwnProperty.call(this.obj, name);
    },
    _observe: function(obj) {
        if (Object.prototype.hasOwnProperty.call(obj, 'observer')) {
            obj = this.app.api(obj.observer, obj, this.name);
        }

        return obj;
    },
    _background: function(type, color) {
        var func = (type === 'remove') ? 'removeClass' : 'addClass';
        this.$icon[func](this.prefix + '-button-icon-color').css({
            'background-color': color,
            'color': (color !== '') ? this.app.color.invert(color) : ''
        });
    },
    _buildFromElement: function(element) {
        this.$button = this.dom(element);
        this.$button.addClass(this.prefix + '-button-target');
        this._buildData();
    },
    _build: function(name, $container) {

        this._buildTitle();
        this._buildElement();
        this._buildIcon();
        this._buildData($container);
    },
    _buildData: function($container) {

        // data
        this.$button.attr({
            'tabindex': '-1',
            'data-name': this.name,
            'data-command': this.obj.command || false
        });

        this.$button.dataset('instance', this);

        // func
        var func = (this._has('command')) ? '_catch' : '_stop';

        // events
        this.$button.on('click.' + this.prefix + '-button', this[func].bind(this));
        this.$button.on('dragstart.' + this.prefix + '-button', function(e) { e.preventDefault(); return; });

        if ($container) {
            this._buildTooltip();
            this._buildBackground();
            this._buildPosition($container);
        }
    },
    _buildTitle: function() {
        this.title = (typeof this.obj.title !== 'undefined') ? this.lang.parse(this.obj.title) : '';
    },
    _buildElement: function() {
        this.$button = this.dom('<a href="#"></a>');
        this.$button.addClass(this.prefix + '-button ' + this.prefix + '-button-target');

        if (this.type) {
            this.$button.addClass(this.prefix + '-button-' + this.type);
        }

        if (this._has('classname')) {
            this.$button.addClass(this.obj.classname);
        }
    },
    _buildIcon: function() {
        var isIcon = this._has('icon');
        var span = '<span class="' + this.prefix + '-icon-' + this.name + '"></span>'

        this.$icon = this._buildIconElement();

        if (isIcon && this.obj.icon !== true) {
            if (this.obj.icon.search(/</) !== -1) {
                span = this.obj.icon;
            }
            else {
                span = '<span class="' + this.prefix + '-icon-' + this.obj.icon + '"></span>';
            }
        }

        // buttons.icons
        if (this.opts.buttons.icons && typeof this.opts.buttons.icons[this.name] !== 'undefined') {
            span = this.opts.buttons.icons[this.name];
        }

        this.$icon.append(span);
        this.$button.append(this.$icon);
    },
    _buildIconElement: function() {
        return this.dom('<span>').addClass(this.prefix + '-button-icon');
    },
    _buildTooltip: function() {
        if (this.type === 'toolbar' || (this.type === 'context' && this.opts.tooltip.context)) {
            this.app.tooltip.build(this.$button, this.title);
        }
    },
    _buildBackground: function() {
        if (this._has('background')) {
            this.setBackground(this.obj.background);
        }
    },
    _buildPosition: function($container) {
        if (this._has('position')) {
            var pos = this.obj.position;
            if (pos === 'first') {
                $container.prepend(this.$button);
            }
            else if (typeof pos === 'object') {

                var type = (Object.prototype.hasOwnProperty.call(pos, 'after')) ? 'after' : 'before';
                var name = pos[type];
                var $el = this._findPositionElement(name, $container);

                if ($el) {
                    $el[type](this.$button);
                }
                else {
                    $container.append(this.$button);
                }
            }
        }
        else {
            $container.append(this.$button);
        }
    },
    _findPositionElement: function(name, $container) {
        var $el;
        if (Array.isArray(name)) {
            for (var i = 0; i < name.length; i++) {
                $el = $container.find('[data-name=' + name[i] + ']');
                if ($el.length !== 0) break;
            }
        }
        else {
            $el = $container.find('[data-name=' + name + ']');
        }

        return ($el.length !== 0) ? $el : 0;
    },
    _stop: function(e) {
        e.preventDefault();
        e.stopPropagation();
    },
    _catch: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $btn = this.dom(e.target).closest('.' + this.prefix + '-button-target');
        if ($btn.hasClass('disable')) return;

        // editor focus
        this.app.editor.setFocus();

        var command = $btn.attr('data-command');
        var name = $btn.attr('data-name');
        var instance = $btn.dataget('instance');

        // command
        this.app.api(command, this.getParams(), instance, name, e);
        this.app.tooltip.close();
    }
});
Revolvapp.add('module', 'color', {
    init: function() {},
    normalize: function(color) {
        color = (color) ? this.rgb2hex(color) : color;
        color = (color) ? this.shorthex2long(color) : color;

        return color;
    },
    replaceRgbToHex: function(html) {
        return html.replace(/rgb\((.*?)\)/g, function (match, capture) {
            var a = capture.split(',');
            var b = a.map(function(x) {
                x = parseInt(x).toString(16);
                return (x.length === 1) ? '0' + x : x;
            });

            return '#' + b.join("");
        });
    },
    rgb2hex: function(color) {
        if (color.search(/^rgb/i) === -1) {
            return color;
        }

        var arr = color.match(/^rgba?[\s+]?\([\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?/i);

        return (arr && arr.length === 4) ? "#" +
        ("0" + parseInt(arr[1],10).toString(16)).slice(-2) +
        ("0" + parseInt(arr[2],10).toString(16)).slice(-2) +
        ("0" + parseInt(arr[3],10).toString(16)).slice(-2) : '';
    },
    shorthex2long: function(hex) {
        hex = this._removeHexDiese(hex);
        return (hex.length === 3) ? '#' + hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2] : '#' + hex;
    },
    invert: function (hex) {
        hex = (hex === '' || hex === null || typeof hex === 'undefined') ? '#ffffff' : hex;
        hex = this.normalize(hex);
        hex = this._removeHexDiese(hex);

        var r = parseInt(hex.slice(0, 2), 16),
            g = parseInt(hex.slice(2, 4), 16),
            b = parseInt(hex.slice(4, 6), 16);

        return ((r * 0.299 + g * 0.587 + b * 0.114) > 186) ? 'black' : 'white';
    },

    // private
    _removeHexDiese: function(hex) {
        return (hex.indexOf('#') === 0) ? hex.slice(1) : hex;
    }
});
Revolvapp.add('module', 'element', {
    // is
    is: function(el, type, extend) {
        var res = false;
        var node = (type === 'text') ? el : this._getNode(el);

        if (type === 'inline') {
            res = (this._isElement(node) && this._isInlineTag(node.tagName, extend));
        }
        else if (type === 'blocks') {
            res = (this._isElement(node) && node.hasAttribute('data-' + this.prefix + '-type'));
        }
        else if (type === 'blocks-first') {
            res = (this._isElement(node) && node.hasAttribute('data-' + this.prefix + '-first-level'));
        }
        else if (type === 'block') {
            res = (this._isElement(node) && this._isBlockTag(node.tagName, extend));
        }
        else if (type === 'element') {
            res = this._isElement(node);
        }
        else if (type === 'text') {
            res = (typeof node === 'string' && !/^\s*<(\w+|!)[^>]*>/.test(node)) ? true : this.isTextNode(node);
        }
        else if (type === 'list') {
            res = (this._isElement(node) && (['ul', 'ol'].indexOf(node.tagName.toLowerCase()) !== -1));
        }
        else if (type === 'heading') {
            res = (this._isElement(node) && (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].indexOf(node.tagName.toLowerCase()) !== -1));
        }

        return res;
    },
    isEmptyOrImageInline: function(el) {
        var node = this.dom(el).get();
        if (!node || node.nodeType === 3) {
            return false;
        }

        var tag = node.tagName.toLowerCase();
        var tags = ['svg', 'img'];
        var noeditattr = (node.getAttribute('contenteditable') === 'false');
        var isInline = this.is(node, 'inline');
        if (
                (isInline && this.isEmpty(node)) ||
                (isInline && noeditattr) ||
                (tags.indexOf(tag) !== -1)
            ) {
            return true;
        }

        return false;
    },
    isEmpty: function(el) {
        var node = this._getNode(el);
        if (node) {
            return (node.nodeType === 3) ? (node.textContent.trim().replace(/\n/, '') === '') : (node.innerHTML === '');
        }

        return false;
    },
    isTag: function(el, tag) {
        return (this._getNode(el).tagName.toLowerCase() === tag);
    },
    isTextNode: function(el) {
        var node = this._getNode(el);

        return (node && node.nodeType && node.nodeType === 3);
    },
    isVisible: function(el) {
        var node = this._getNode(el);

        return !!(node.offsetWidth || node.offsetHeight || node.getClientRects().length);
    },
    isScrollVisible: function(el) {
        var $scrollTarget = this.app.scroll.getTarget();
        var $el = this.dom(el);
        var docViewTop = $scrollTarget.scrollTop();
        var docViewBottom = docViewTop + $scrollTarget.height();
        var elemTop = $el.offset().top;

        return (elemTop <= docViewBottom);
    },

    // get
    getFirstLevel: function(el) {
        return this.dom(el).closest('[data-' + this.prefix + '-first-level]');
    },
    getDataBlock: function(el) {
        return this.dom(el).closest('[data-' + this.prefix + '-type]');
    },
    getType: function(el) {
        return this.dom(el).attr('data-' + this.prefix + '-type');
    },
    getAllInlines: function(inline) {
        var inlines = [];
        var node = inline;
        while (node) {
            if (this.is(node, 'inline')) {
                inlines.push(node);
            }

            node = node.parentNode;
        }

        return inlines;
    },
    getClosest: function(el, types) {
        return this.dom(el).closest(this.getTypesSelector(types));
    },
    getParents: function(el, types) {
        return this.dom(el).parents(this.getTypesSelector(types));
    },
    getChildren: function(el, types) {
        return this.dom(el).find(this.getTypesSelector(types));
    },
    getTypesSelector: function(types) {
        return '[data-' + this.prefix + '-type=' + types.join('],[data-' + this.prefix + '-type=') + ']';
    },

    // has
    hasClass: function(el, value) {
        value = (typeof value === 'string') ? [value] : value;

        var $el = this.dom(el);
        var count = value.length;
        var z = 0;
        for (var i = 0; i < count; i++) {
            if ($el.hasClass(value[i])) {
                z++;
            }
        }

        return (count === z);
    },

    // scroll
    scrollTo: function($el, tolerance) {
        if (!this.isScrollVisible($el)) {
            tolerance = tolerance || 60;
            var offset = $el.offset();
            var $target = this.app.scroll.getTarget();
            var value = offset.top - tolerance;
            $target.scrollTop(value);

            setTimeout(function() {
                $target.scrollTop(value);
            }, 1);

        }
    },

    // replace
    replaceToTag: function(el, tag, keepchildnodes) {
        return this.dom(el).replaceWith(function(node) {

            var $el = this.dom('<' + tag + '>');
            if (!keepchildnodes) {
                $el.append(node.innerHTML);
            }

            if (node.attributes) {
                var attrs = node.attributes;
                for (var i = 0; i < attrs.length; i++) {
                    $el.attr(attrs[i].nodeName, attrs[i].value);
                }
            }

            if (keepchildnodes) {
                while (node.childNodes.length > 0) {
                    $el.append(this.dom(node.firstChild));
                }
            }

            return $el;
        }.bind(this));
    },

    // split
    split: function(el) {
        var $el = this.dom(el);
        el = $el.get();
        var tag = el.tagName.toLowerCase();
        var fragment = this.app.content.extractHtmlFromCaret(el);
        if (fragment.nodeType && fragment.nodeType === 11) {
            fragment = this.dom(fragment.childNodes);
        }

        var $secondPart = this.dom('<' + tag + ' />');
        $secondPart = this.cloneAttrs(el, $secondPart);
        $secondPart.append(fragment);
        $el.after($secondPart);

        var $last = $el.children().last();
        if (this.is($last, 'inline')) {
            var html = $last.html();
            html = this.app.utils.removeInvisibleChars(html);
            if (html === '') {
                $last.remove();
            }
        }

        var type = this.getType($secondPart);
        if (type) {
            this.app.create('block.' + type, $secondPart, true);
        }

        if ($el.html() === '') $el.remove();

        return $secondPart;
    },

    // clone
    cloneEmpty: function(el) {
        var $el = this.dom(el);
        var tag =  $el.get().tagName.toLowerCase();
        var $clone = this.dom('<' + tag + '>');

        return $clone;
    },
    cloneAttrs: function(elFrom, elTo) {
        var $elTo = this.dom(elTo);
        var attrs = this._getNode(elFrom).attributes;
        var len = attrs.length;
        while (len--) {
            var attr = attrs[len];
            $elTo.attr(attr.name, attr.value);
        }

        return $elTo;
    },

    // attrs
    getAttrs: function(el) {
        var node = this._getNode(el);
        var attr = {};
        if (node.attributes != null && node.attributes.length) {
            for (var i = 0; i < node.attributes.length; i++) {
                var val = node.attributes[i].nodeValue;
                val = (this._isNumber(val)) ? parseFloat(val) : this._getBooleanFromStr(val);
                attr[node.attributes[i].nodeName] = val;
            }
        }

        return attr;
    },
    removeEmptyAttrs: function(el, attrs) {
        var $el = this.dom(el);
        var name = attrs.join(' ');
        var res = false;

        if (typeof $el.attr(name) === 'undefined' || $el.attr(name) === null) {
            res = true;
        }
        else if ($el.attr(name) === '') {
            $el.removeAttr(name);
            res = true;
        }

        return res;
    },

    // blocks
    getBlocks: function(el, parsertags, extendtags) {
        var node = this._getNode(el);
        var nodes = node.childNodes;
        var finalNodes = [];
        var tags = parsertags || this.opts.tags.parser;
        if (extendtags) {
            tags = this.app.utils.extendArray(tags, extendtags);
        }

        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeType === 1 && tags.indexOf(nodes[i].tagName.toLowerCase()) !== -1) {
                finalNodes.push(nodes[i]);
            }
        }

        return finalNodes;
    },
    hasBlocks: function(el) {
        return (this.getBlocks(el).length !== 0);
    },

    // siblings
    hasTextSiblings: function(el) {
        var node = this._getNode(el);
        var hasPrev = (node.previousSibling && node.previousSibling.nodeType === 3 && !this.isEmpty(node.previousSibling));
        var hasNext = (node.nextSibling && node.nextSibling.nodeType === 3 && !this.isEmpty(node.nextSibling));

        return (hasPrev || hasNext);
    },

    // private
    _getNode: function(el) {
        return this.dom(el).get();
    },
    _getBooleanFromStr: function(str) {
        if (str === 'true') return true;
        else if (str === 'false') return false;

        return str;
    },
    _isBlockTag: function(tag, extend) {
        var arr = this.app.utils.extendArray(this.opts.tags.block, extend);

        return (arr.indexOf(tag.toLowerCase()) !== -1);
    },
    _isInlineTag: function(tag, extend) {
        var arr = this.app.utils.extendArray(this.opts.tags.inline, extend);

        return (arr.indexOf(tag.toLowerCase()) !== -1);
    },
    _isElement: function(node) {
        return (node && node.nodeType && node.nodeType === 1);
    },
    _isTag: function(tag) {
        return (tag !== undefined && tag);
    },
    _isNumber: function(str) {
        return !isNaN(str) && !isNaN(parseFloat(str));
    }
});
Revolvapp.add('module', 'fragment', {
    build: function(node) {
        return (this.is(node)) ? node : this.create(node);
    },
    insert: function(fragment) {
        var sel = this.app.selection.get();
        if (!sel.range) return;

        if (sel.collapsed) {
            var start = sel.range.startContainer;
            if (start.nodeType !== 3 && start.tagName === 'BR') {
                start.parentNode.removeChild(start);
            }
        }
        else {
            sel.range.deleteContents();
        }

        if (fragment.frag) {
            sel.range.insertNode(fragment.frag);
        }
        else {
            sel.range.insertNode(fragment);
        }
    },
    createContainer: function(html) {
        var $div = this.dom('<div>');

        if (typeof html === 'string') $div.html(html);
        else $div.append(this.dom(html).clone(true));

        return $div.get();
    },
    create: function(html) {
        var el = (typeof html === 'string') ? this.createContainer(html) : html;
        var frag = document.createDocumentFragment(), node, firstNode, lastNode;
        var nodes = [];
        var i = 0;
        while ((node = el.firstChild)) {
            i++;
            var n = frag.appendChild(node);
            if (i === 1) firstNode = n;

            nodes.push(n);
            lastNode = n;
        }

        return { frag: frag, first: firstNode, last: lastNode, nodes: nodes };
    },
    is: function(obj) {
        return (typeof obj === 'object' && obj.frag);
    }
});
Revolvapp.add('module', 'lang', {
    init: function() {
        this.langKey = this.app.setting.get('editor.lang');
        this.vars = this._build();
    },
    get: function(name) {
        var value = this._get(name, this.vars);
        if (typeof value === 'undefined' && this.langKey !== 'en') {
            value = this._get(name, $RE.lang['en']);
        }

        return (typeof value === 'undefined') ? '' : value;
    },
    parse: function(str) {
        if (typeof str !== 'string') return str;

        var matches = str.match(/## (.*?) ##/g);
        if (matches) {
            for (var i = 0; i < matches.length; i++) {
                var key = matches[i].replace(/^##\s/g, '').replace(/\s##$/g, '');
                str = str.replace(matches[i], this.get(key));
            }
        }

        return str;
    },

    // private
    _get: function(name, vars) {
        var value;
        var arr = name.split('.');

        if (arr.length === 1) value = vars[name];
        else value = (typeof vars[arr[0]] !== 'undefined') ? vars[arr[0]][arr[1]] : undefined;

        return value;
    },
    _build: function() {
        var vars = $RE.lang['en'];
        if (this.langKey !== 'en') {
            vars = ($RE.lang[this.langKey] !== 'undefined') ? $RE.lang[this.langKey] : vars;
        }

        return vars;
    }
});
Revolvapp.add('module', 'progress', {
    stop: function() {
        this.hide();
    },
    show: function() {
        this.hide();

        this.$progress = this.dom('<div>').addClass(this.prefix + '-editor-progress');
        this.$progress.attr('id', this.prefix + '-progress');

        this.$progressBar = this.dom('<span>');
        this.$progress.append(this.$progressBar);
        this.app.$body.append(this.$progress);
    },
    hide: function() {
        this.app.$body.find('#' + this.prefix + '-progress').remove();
    }
});
Revolvapp.add('module', 'scroll', {
    init: function() {
        this.scrolltop = false;
    },
    save: function() {
        this.scrolltop = this.getTarget().scrollTop();
    },
    restore: function() {
        if (this.scrolltop !== false) {
            this.getTarget().scrollTop(this.scrolltop);
            this.scrolltop = false;
        }
    },
    isTarget: function() {
        return (this.opts.editor.scrollTarget !== window);
    },
    getTarget: function() {
        return this.dom(this.opts.editor.scrollTarget);
    }
});
Revolvapp.add('module', 'setting', {
    init: function() {
        this.opts = this._build();
    },
    dump: function() {
        return this.opts;
    },
    has: function(name) {
        var value;
        var arr = name.split('.');

        if (arr.length === 1) value = (typeof this.opts[name] !== 'undefined');
        else value = (typeof this.opts[arr[0]] !== 'undefined' && typeof this.opts[arr[1]] !== 'undefined');

        return value;
    },
    set: function(section, name, value) {
        if (typeof this.opts[section] === 'undefined') this.opts[section] = {};

        if (typeof value === 'undefined') this.opts[section] = name;
        else this.opts[section][name] = value;
    },
    get: function(name) {
        var value;
        var arr = name.split('.');

        if (arr.length === 1) value = this.opts[name];
        else value = (typeof this.opts[arr[0]] !== 'undefined') ? this.opts[arr[0]][arr[1]] : undefined;

        return value;
    },

    // private
    _build: function() {
        var opts = $RE.extend(true, {}, $RE.opts, this.app.initialSettings);
        opts = $RE.extend(true, opts, $RE.settings);

        return opts;
    }
});
Revolvapp.add('module', 'shortcut', {
    init: function() {
        // remove
        if (this.opts.shortcutsRemove) {
            var keys = this.opts.shortcutsRemove;
            for (var i = 0; i < keys.length; i++) {
                this.remove(keys[i]);
            }
        }

        // local
        this.shortcuts = this.opts.shortcuts;

        // based on https://github.com/jeresig/jquery.hotkeys
        this.hotkeys = {
            8: "backspace", 9: "tab", 10: "return", 13: "return", 16: "shift", 17: "ctrl", 18: "alt", 19: "pause",
            20: "capslock", 27: "esc", 32: "space", 33: "pageup", 34: "pagedown", 35: "end", 36: "home",
            37: "left", 38: "up", 39: "right", 40: "down", 45: "insert", 46: "del", 59: ";", 61: "=",
            96: "0", 97: "1", 98: "2", 99: "3", 100: "4", 101: "5", 102: "6", 103: "7",
            104: "8", 105: "9", 106: "*", 107: "+", 109: "-", 110: ".", 111 : "/",
            112: "f1", 113: "f2", 114: "f3", 115: "f4", 116: "f5", 117: "f6", 118: "f7", 119: "f8",
            120: "f9", 121: "f10", 122: "f11", 123: "f12", 144: "numlock", 145: "scroll", 173: "-", 186: ";", 187: "=",
            188: ",", 189: "-", 190: ".", 191: "/", 192: "`", 219: "[", 220: "\\", 221: "]", 222: "'"
        };

        this.hotkeysShiftNums = {
            "`": "~", "1": "!", "2": "@", "3": "#", "4": "$", "5": "%", "6": "^", "7": "&",
            "8": "*", "9": "(", "0": ")", "-": "_", "=": "+", ";": ": ", "'": "\"", ",": "<",
            ".": ">",  "/": "?",  "\\": "|"
        };
    },
    add: function(keys, obj) {
        this.shortcuts[keys] = obj;
    },
    remove: function(keys) {
        this.opts.shortcutsBase = this._remove(keys, this.opts.shortcutsBase);
        this.opts.shortcuts = this._remove(keys, this.opts.shortcuts);
    },
    popup: function(params, button) {

        var meta = (/(Mac|iPhone|iPod|iPad)/i.test(navigator.platform)) ? '<b>&#8984;</b>' : 'ctrl';
        var items = {};
        var z = 0;

        // items
        z = this._buildPopupItems(items, z, this.opts.shortcutsBase, meta, 'base');
        this._buildPopupItems(items, z, this.opts.shortcuts, meta);

        // create
        this.app.popup.create('shortcuts', {
            width: '360px',
            items: items
        });

        // open
        this.app.popup.open({ button: button });
    },
    handle: function(e) {
        this.triggered = false;

        // disable browser's hot keys for bold and italic if shortcuts off
        if (this.shortcuts === false) {
            if ((e.ctrlKey || e.metaKey) && (e.which === 66 || e.which === 73)) {
                e.preventDefault();
            }
            return true;
        }

        // build
        if (e.ctrlKey || e.metaKey || e.shoftKey || e.altKey) {
            for (var key in this.shortcuts) {
                this._build(e, key, this.shortcuts[key]);
            }
        }

        return (this.triggered);
    },

    // private
    _buildPopupItems: function(items, z, shortcuts, meta, type) {
        for (var key in shortcuts) {
            var $item = this.dom('<div>').addClass(this.prefix + '-popup-shortcut-item');
            var title = (type === 'base') ? shortcuts[key] : shortcuts[key].title;

            var $title = this.dom('<span>').addClass(this.prefix + '-popup-shortcut-title').html(this.lang.parse(title));
            var $kbd = this.dom('<span>').addClass(this.prefix + '-popup-shortcut-kbd');

            var name = (type === 'base') ? key.replace('meta', meta) : shortcuts[key].name.replace('meta', meta);
            var arr = name.split('+');
            for (var i = 0; i < arr.length; i++) {
                arr[i] = '<span>' + arr[i] + '</span>';
            }
            $kbd.html(arr.join('+'));

            $item.append($title);
            $item.append($kbd);

            items[z] = { html: $item };

            z++;
        }

        return z;
    },
    _build: function(e, str, obj) {
        var keys = str.split(',');
        var len = keys.length;
        for (var i = 0; i < len; i++) {
            if (typeof keys[i] === 'string' && !Object.prototype.hasOwnProperty.call(obj, 'trigger')) {
                this._handler(e, keys[i].trim(), obj);
            }
        }
    },
    _handler: function(e, keys, obj) {
        keys = keys.toLowerCase().split(" ");

        var special = this.hotkeys[e.keyCode];
        var character = (e.which !== 91) ? String.fromCharCode(e.which).toLowerCase() : false;
        var modif = "", possible = {};
        var cmdKeys = ["meta", "ctrl", "alt", "shift"];

        for (var i = 0; i < cmdKeys.length; i++) {
            var specialKey = cmdKeys[i];
            if (e[specialKey + 'Key'] && special !== specialKey) {
                modif += specialKey + '+';
            }
        }

        // right cmd
        if (e.keyCode === 93) {
            modif += 'meta+';
        }

        if (special) possible[modif + special] = true;
        if (character) {
            possible[modif + character] = true;
            possible[modif + this.hotkeysShiftNums[character]] = true;

            // "$" can be triggered as "Shift+4" or "Shift+$" or just "$"
            if (modif === "shift+") {
                possible[this.hotkeysShiftNums[character]] = true;
            }
        }

        var len = keys.length;
        for (var z = 0; z < len; z++) {
            if (possible[keys[z]]) {

                e.preventDefault();
                this.triggered = true;

                this.app.api(obj.command, obj.params, e);
                return;
            }
        }
    },
    _remove: function(keys, obj) {
        return Object.keys(obj).reduce(function(object, key) {
            if (key !== keys) { object[key] = obj[key] }
            return object;
        }, {});
    }
});
Revolvapp.add('module', 'tooltip', {
    init: function() {
        this.classname = this.prefix + '-tooltip';
        this.eventname = this.prefix + '-button-' + this.uuid;
    },
    stop: function() {
        this.close();
    },
    build: function($btn, title) {
        title = this._cleanTitle(title);
        if (title) {
            $btn.attr('data-tooltip', title);
            $btn.on('mouseover.' + this.eventname, this.open.bind(this));
            $btn.on('mouseout.' + this.eventname, this.close.bind(this));
        }
    },
    open: function(e) {
        var $btn = this._getButton(e);
        if (this.app.popup.isOpen() || $btn.hasClass('disable')) {
            return;
        }

        // create
        this.$tooltip = this._create($btn);

        // position
        this._setPosition($btn);
        this._fixBSModal();

        // append
        this.app.$body.append(this.$tooltip);
    },
    close: function() {
        this.app.$body.find('.' + this.classname).remove();
    },

    // private
    _create: function($btn) {
        return this.dom('<span>').addClass(this.classname).html($btn.attr('data-tooltip'))
    },
    _cleanTitle: function(title) {
        return (title) ? title.replace(/(<([^>]+)>)/gi, '') : false;
    },
    _setPosition: function($btn) {
        var offset = $btn.offset();
        var height = $btn.height();

        this.$tooltip.css({
            top: (offset.top + height) + 'px',
            left: (offset.left) + 'px'
        });
    },
    _fixBSModal: function() {
        if (this.opts.bsmodal) {
            this.$tooltip.css('z-index', 1060);
        }
    },
    _getButton: function(e) {
        return this.dom(e.target).closest('.' + this.prefix + '-button-target');
    }
});
Revolvapp.add('class', 'upload', {
    defaults: {
        type: 'image',
        box: false,
        url: false,
        cover: true, // 'cover'
        name: 'file',
        data: false,
        multiple: true,
        placeholder: false,
        hidden: true,
        target: false,
        success: false,
        error: false,
        remove: false,
        trigger: false,
        input: false
    },
    init: function($el, params, trigger) {
        this.eventname = this.prefix + '-upload';

        if ($el) {
            this._build($el, params, trigger);
        }
    },
    send: function(e, files, params, trigger) {
        this.p = this._buildParams(params, trigger);
        this._send(e, files);
    },
    complete: function(response, e) {
        this._complete(response, e);
    },

    // api
    setImage: function(url) {
        if (this.p.input) return;

        if (this.$image) this.$image.remove();
        if (this.$remove) this.$remove.remove();

        if (url === '') {
            this.$placeholder.show();
        }
        else {
            this.$placeholder.hide();
            this._buildImage(url);

            if (this.p.remove) {
                this._buildRemove();
            }
        }
    },

    // build
    _build: function($el, params, trigger) {
        this.p = this._buildParams(params, trigger);
        this.$element = this.dom($el);

        var tag = this.$element.get().tagName;
        if (tag === 'INPUT') {
            this._buildByInput();
        }
        else {
            this._buildByBox();
        }
    },
    _buildImage: function(url) {
        this.$image = this.dom('<img>');
        this.$image.attr('src', url);
        this.$box.append(this.$image);

        if (this.p.input === false) {
            this.$box.off('click.' + this.eventname);
            this.$image.on('click.' + this.eventname, this._click.bind(this));
        }
    },
    _buildRemove: function() {
        this.$remove = this.dom('<span>');
        this.$remove.addClass(this.prefix + '-upload-remove');
        this.$remove.on('click', this._removeImage.bind(this));
        this.$box.append(this.$remove);
    },
    _buildParams: function(params, trigger) {
        params = $RE.extend(true, this.defaults, params);
        if (trigger) params.trigger = trigger;

        return params;
    },
    _buildByInput: function() {

        this.$input = this.$element;

        // box
        if (this.p.box) {
            this._buildBox();
            this._buildPlaceholder();
        }
        // input
        else {
            this.p.input = true;
        }

        this._buildAccept();
        this._buildMultiple();
        this._buildEvents();
    },
    _buildByBox: function() {
        this._buildInput();
        this._buildAccept();
        this._buildMultiple();
        this._buildBox();
        this._buildPlaceholder();
        this._buildEvents();
    },
    _buildBox: function() {
        this.$box = this.dom('<div>').addClass(this.prefix + '-form-upload-box');
        this.$element.before(this.$box);

        // cover
        if (this.p.cover === false) {
            this.$box.addClass(this.prefix + '-form-upload-cover-off');
        }

        // hide
        if (this.p.hidden) {
            this.$element.hide();
        }
    },
    _buildPlaceholder: function() {
        if (!this.p.placeholder) return;
        this.$placeholder = this.dom('<span>').addClass(this.prefix + '-form-upload-placeholder');
        this.$placeholder.html(this.p.placeholder);
        this.$box.append(this.$placeholder);
    },
    _buildInput: function() {
        this.$input = this.dom('<input>');
        this.$input.attr('type', 'file');
        this.$input.attr('name', this._getUploadParam());
        this.$input.hide();

        this.$element.before(this.$input);
    },
    _buildAccept: function() {
        if (this.p.type !== 'image') return;

        var types = this.opts.image.types.join(',');
        this.$input.attr('accept', types);
    },
    _buildMultiple: function() {
        if (this.p.type !== 'image') return;

        if (this.p.multiple) {
            this.$input.attr('multiple', 'multiple');
        }
        else {
            this.$input.removeAttr('multiple');
        }
    },
    _buildEvents: function() {
        this.$input.on('change.' + this.eventname + '-' + this.uuid, this._change.bind(this));

        if (this.p.input === false) {
            this.$box.on('click.' + this.eventname, this._click.bind(this));
            this.$box.on('drop.' + this.eventname, this._drop.bind(this));
            this.$box.on('dragover.' + this.eventname, this._dragover.bind(this));
            this.$box.on('dragleave.' + this.eventname, this._dragleave.bind(this));
        }
    },
    _buildData: function(name, files, data) {
        if (this.p.multiple === 'single') {
            data.append(name, files[0]);
        }
        else if (this.p.multiple) {
            for (var i = 0; i < files.length; i++) {
                data.append(name + '[]', files[i]);
            }
        }
        else {
            data.append(name + '[]', files[0]);
        }

        return data;
    },

    // remove
    _removeImage: function(e) {
        if (e) {
            e.preventDefault();
            e.stopPropagation();
        }

        if (this.$image) this.$image.remove();
        if (this.$remove) this.$remove.remove();

        this.$placeholder.show();

        if (this.p.input === false) {
            this.$box.on('click.' + this.eventname, this._click.bind(this));
        }

        if (e) {
            this.app.api(this.p.remove, e);
        }
    },

    // get
    _getUploadParam: function() {
        return this.p.name;
    },


    // events
    _click: function(e) {
        e.preventDefault();
        this.$input.click();
    },
    _change: function(e) {
        this._send(e, this.$input.get().files);
    },
    _drop: function(e) {
        e.preventDefault();
        this._send(e);
    },
    _dragover: function(e) {
        e.preventDefault();
        this._setStatus('hover');
        return false;
    },
    _dragleave: function(e) {
        e.preventDefault();
        this._removeStatus();
        return false;
    },

    // set
    _setStatus: function(status) {
        if (this.p.input || !this.p.box) return;
        this._removeStatus();
        this.$box.addClass(this.prefix + '-form-upload-' + status);
    },

    // remove
    _removeStatus: function() {
        if (this.p.input || !this.p.box) return;
        var status = ['hover', 'error'];
        for (var i = 0; i < status.length; i++) {
            this.$box.removeClass(this.prefix + '-form-upload-' + status[i]);
        }
    },

    // send
    _send: function(e, files) {
        files =  files || e.dataTransfer.files;

        var data = new FormData();
        var name = this._getUploadParam();

        data = this._buildData(name, files, data);
        data = this.app.utils.extendData(data, this.p.data);

        // send data
        this._sendData(e, files, data);
    },
    _sendData: function(e, files, data) {
        if (typeof this.p.url === 'function') {
            this.p.url.call(this.app, this, { data: data, files: files, e: e });
        }
        else {
            this.app.progress.show();
            this.ajax.post({
                url: this.p.url,
                data: data,
                before: function(xhr) {
                    var event = this.app.broadcast('upload.before.send', { xhr: xhr, data: data, files: files, e: e });
                    if (event.isStopped()) {
                        this.app.progress.hide();
                        return false;
                    }
                }.bind(this),
                success: function(response) {
                    this._complete(response, e);
                }.bind(this),
                error: function(response) {
                    this._complete(response, e);
                }.bind(this)
            });
        }
    },

    // complete
    _complete: function(response, e) {
        if (response && response.error) {
            this._setStatus('error');

            if (this.p.error) {
                this.app.broadcast('upload.error', { response: response });
                this.app.api(this.p.error, response, e);
            }
        }
        else {
            this._removeStatus();
            this._trigger(response);

            if (this.p.success) {
                this.app.broadcast('upload.complete', { response: response });
                this.app.api(this.p.success, response, e);
            }
        }

        setTimeout(function() {
            this.app.progress.hide()
        }.bind(this), 500);
    },
    _trigger: function(response) {
        if (this.p.trigger) {
            if (response && response.url) {
                var instance = this.p.trigger.instance;
                var method = this.p.trigger.method;
                instance[method].call(instance, response.url);
            }
        }
    }
});
Revolvapp.add('module', 'utils', {

    // mobile
    isMobile: function() {
        return /(iPhone|iPad|iPod|Android)/.test(navigator.userAgent);
    },

    // invisible chars
    createInvisibleChar: function() {
        return document.createTextNode(this.opts.markerChar);
    },
    searchInvisibleChars: function(str) {
        return str.search(/^\uFEFF$/g);
    },
    removeInvisibleChars: function(str) {
        return str.replace(/\uFEFF/g, '');
    },

    // wrapper
    wrap: function(html, func) {
        var $w = this.dom('<div>').html(html);
        func($w);

        html = $w.html();
        $w.remove();

        return html;
    },

    // arrays
    extendArray: function(arr, extend) {
        arr = arr.concat(arr);
        if (extend) {
            for (var i = 0 ; i < extend.length; i++) {
                arr.push(extend[i]);
            }
        }

        return arr;
    },
    removeFromArrayByValue: function(arr, val) {
        val = (Array.isArray(val)) ? val : [val];
        var index;
        for (var i = 0; i < val.length; i++) {
            index = arr.indexOf(val[i]);
            if (index > -1) arr.splice(index, 1);
        }
        return arr;
    },
    sumOfArray: function(arr) {
        return arr.reduce(function(a, b) {
            return parseInt(a) + parseInt(b);
        }, 0);
    },

    // object
    getObjectIndex: function(obj, key) {
        return Object.keys(obj).indexOf(key);
    },
    insertToObject: function (key, value, obj, pos) {
        return Object.keys(obj).reduce(function(ac, a, i) {
            if (i === pos) ac[key] = value;
            ac[a] = obj[a];
            return ac;
        }, {});
    },

    // random
    getRandomId: function() {
        var id = '';
        var possible = 'abcdefghijklmnopqrstuvwxyz0123456789';

        for (var i = 0; i < 12; i++) {
            id += possible.charAt(Math.floor(Math.random() * possible.length));
        }

        return id;
    },

    // escape
    escapeRegExp: function(s) {
        return s.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');
    },

    // string
    capitalize: function(str) {
        str = str.toLowerCase();

        return str.charAt(0).toUpperCase() + str.slice(1);
    },

    // data
    extendData: function(data, obj) {
        for (var key in obj) {
            if (key === 'elements') {
                data = this._extendDataElements(data, obj[key]);
            }
            else {
                data = this._setData(data, key, obj[key]);
            }
        }

        return data;
    },
    _extendDataElements: function(data, value) {
        this.dom(value).each(function($node) {
            if ($node.get().tagName === 'FORM') {
                var serializedData = $node.serialize(true);
                for (var z in serializedData) {
                    data = this._setData(data, z, serializedData[z]);
                }
            }
            else {
                var name = ($node.attr('name')) ? $node.attr('name') : $node.attr('id');
                data = this._setData(data, name, $node.val());
            }
        }.bind(this));

        return data;
    },
    _setData: function(data, name, value) {
        if (data instanceof FormData) data.append(name, value);
        else data[name] = value;

        return data;
    }
});
Revolvapp.add('module', 'offset', {
    get: function(el) {
        el = this._getEl(el);

        var sel = this.app.editor.getWinNode().getSelection();
        var offset = false;

        if (sel && sel.rangeCount > 0) {
            var range = sel.getRangeAt(0);
            if (el.contains(sel.anchorNode)) {
                var cloned = range.cloneRange();
                cloned.selectNodeContents(el);
                cloned.setEnd(range.startContainer, range.startOffset);

                var start = cloned.toString().length;
                offset = {
                    start: start,
                    end: start + range.toString().length
                };
            }
        }

        return offset;
    },
    set: function(el, offset) {
        if (offset === false) {
            offset = { start: 0, end: 0 };
        }

        el = this._getEl(el);

        var charIndex = 0, range = this.app.editor.getDocNode().createRange();
        var nodeStack = [el], node, foundStart = false, stop = false;

        range.setStart(el, 0);
        range.collapse(true);

        while (!stop && (node = nodeStack.pop())) {
            if (node.nodeType === 3) {
                var nextCharIndex = charIndex + node.length;

                if (!foundStart && offset.start >= charIndex && offset.start <= nextCharIndex) {
                    range.setStart(node, offset.start - charIndex);
                    foundStart = true;
                }

                if (foundStart && offset.end >= charIndex && offset.end <= nextCharIndex) {
                    range.setEnd(node, offset.end - charIndex);
                    stop = true;
                }

                charIndex = nextCharIndex;
            }
            else {
                var i = node.childNodes.length;
                while (i--) {
                    nodeStack.push(node.childNodes[i]);
                }
            }
        }

        this.app.selection.setRange(range);
    },

    // private
    _getEl: function(el) {
        return (!el) ? this.app.editor.getLayout().get() : this.dom(el).get();
    }
});
Revolvapp.add('module', 'caret', {
    set: function(el, type) {
        var node = this.dom(el).get();
        var range = this.app.editor.getDocNode().createRange();
        var map = { 'start': '_setStart', 'end': '_setEnd', 'before': '_setBefore', 'after': '_setAfter' };

        if (!node || !this._isInPage(node)) {
            return;
        }

        // focus
        this.app.editor.setWinFocus();

        // non editable inline node
        if (this._isInline(node) && this._isNon(node)) {
            if (type === 'start') type = 'before';
            else if (type === 'end') type = 'after';
        }

        // set
        this[map[type]](range, node);
        this.app.selection.setRange(range);
    },
    is: function(el, type, removeblocks, trimmed, br) {
        var node = this.dom(el).get();
        var sel = this.app.editor.getWinNode().getSelection();
        var result = false;

        if (!node || !sel.isCollapsed) {
            return result;
        }

        var position = this._getPosition(node, trimmed, br);
        var size = this._getSize(node, removeblocks, trimmed);

        if (type === 'end') {
            result = (position === size);
        }
        else if (type === 'start') {
            result = (position === 0);
        }

        return result;
    },

    // private
    _setStart: function(range, node) {
        range.setStart(node, 0);
        range.collapse(true);

        // block node has first inline
        var inline = this._getInlineInside(node);
        if (inline) {
            range = this._setStartInline(range, inline);
        }

        // inline node
        if (this._isInline(node)) {
            this._insertInvisibleNode(range);
        }
    },
    _setStartInline: function(range, inline) {
        var inlines = this.app.element.getAllInlines(inline);
        var node = inlines[0];
        range.selectNodeContents(node);
        range.collapse(true);
    },
    _setEnd: function(range, node) {

        // block node has last inline
        var last = (node.nodeType === 1) ? node.lastChild : false;
        var lastInline = (last && this._isInline(last));
        if (lastInline) {
            node = last;
        }

        range.selectNodeContents(node);
        range.collapse(false);
    },
    _setBefore: function(range, node) {
        range.setStartBefore(node);
        range.collapse(true);

        // inline node
        if (this._isInline(node)) {
            this._insertInvisibleNode(range, node);
        }
    },
    _setAfter: function(range, node) {
        range.setStartAfter(node);
        range.collapse(true);

        // inline node
        var tag = (node.nodeType !== 3) ? node.tagName.toLowerCase() : false;
        if (this._isInline(node) || tag === 'br' || tag === 'svg') {
            this._insertInvisibleNode(range);
        }
    },
    _insertInvisibleNode: function(range, before) {
        var textNode = this.app.utils.createInvisibleChar();

        if (before) {
            before.parentNode.insertBefore(textNode, before);
        }
        else {
            range.insertNode(textNode);
        }

        range.selectNodeContents(textNode);
        range.collapse(false);

        return textNode;
    },
    _getInlineInside: function(node) {
        var inline = node.firstChild;
        if (this._isInline(inline)) {
            var inside = inline.firstChild;
            while (inside) {
                if (this._isInline(inside)) {
                    return inside;
                }
                inside = inside.firstChild;
            }

            return inline;
        }
    },
    _getSize: function(node, removeblocks, trimmed) {
        var str;
        var isTextNode = (node.nodeType === 3);

        if (removeblocks && removeblocks.length !== 0) {
            var $node = this.dom(node);
            var $cloned = $node.clone();
            $cloned.find(removeblocks.join(',')).remove();
            str = $cloned.html().trim();
        }
        else {
            str = (isTextNode) ? node.textContent : node.innerHTML;
            str = (isTextNode || trimmed === false) ? str : str.trim();
        }

        return this._trimmed(str, isTextNode, trimmed).length;
    },
    _getPosition: function(node, trimmed, br) {
        var range = this.app.editor.getWinNode().getSelection().getRangeAt(0);
        var caretRange = range.cloneRange();
        var tmp = document.createElement("div");
        var isTextNode = (node.nodeType === 3);

        caretRange.selectNodeContents(node);
        caretRange.setEnd(range.endContainer, range.endOffset);
        tmp.appendChild(caretRange.cloneContents());

        var str = (isTextNode || trimmed === false) ? tmp.innerHTML : tmp.innerHTML.trim();
        var brEnd = (str.search(/<\/?br\s?\/?>$/g) !== -1) ? 1 : 0;
        if (br === false) brEnd = 0;

        str = this._trimmed(str, isTextNode, trimmed);

        return str.length + brEnd;
    },
    _trimmed: function(str, isTextNode, trimmed) {
        if (trimmed === false) {
            str = str.replace(/\n$/g, '');
            return str;
        }

        str = this.app.utils.removeInvisibleChars(str);
        str = str.replace(/<\/?([a-z][a-z0-9]*)\b[^>]*>/gi, '');
        str = str.replace(/\s+/g, ' ');
        if (str !== '' && !isTextNode) {
            str = str.replace(/\s$/, '');
        }

        return str;
    },
    _isInline: function(node) {
        return this.app.element.is(node, 'inline');
    },
    _isInPage: function(node) {
        var isIn = false;
        var doc = this.app.editor.getDocNode();
        if (node && node.nodeType) {
            isIn = (node === doc.body) ? false : doc.body.contains(node);
        }

        return isIn;
    },
    _isNon: function(node) {
        return (node.getAttribute('contenteditable') === 'false');
    }
});
Revolvapp.add('module', 'popup', {
    init: function() {
        this.stack = false;
        this.stacks = [];
        this.name = false;
        this.supername = false;
        this.autoclose = true;
        this.control = false;
        this.saved = false;
    },
    start: function() {
        this._build();
        this._buildDepth();
    },
    stop: function() {
        this._stopEvents();
        this._stop();
    },
    stopStack: function() {
        this._stopEvents();
        this.app.toolbar.unsetToggled();
        this.$popup.removeAttr('data-' + this.prefix + '-popup-name');
        this.$popup.removeClass('open');
    },

    // is
    isOpen: function(name) {
        var opened = this.$popup.hasClass('open');
        if (name) {
            return (this._getName() === name && opened);
        }

        return opened;
    },

    // create
    create: function(name, params) {
        if (this.isOpen(name)) {
            return this.stack;
        }

        this._reset();
        this.name = name;
        this.supername = name;
        this.stack = this._createStack(name, params);

        return this.stack;
    },

    // add
    add: function(name, params) {
        return this._createStack(name, params, true);
    },

    // set
    setStack: function(stack) {
        this.stack = stack;
        this.name = stack.getName();
    },
    setData: function(data) {
        this.stack.setData(data);
    },
    setFocus: function(name) {
        this.stack.setFocus(name);
    },
    setWidth: function(width) {
        this.stack.setWidth(width);
    },

    // get
    getName: function() {
        return this.name;
    },
    getElement: function() {
        return this.$popup;
    },
    getButton: function() {
        return this.button;
    },
    getStack: function(name) {
        return (name) ? this.stacks[name] : this.stack;
    },
    getBody: function() {
        return this.stack.getBody();
    },
    getItems: function() {
        return this.stack.getItems();
    },
    getFooter: function() {
        return this.stack.getFooter();
    },
    getFooterPrimary: function() {
        return this.stack.getFooterPrimary();
    },
    getTool: function(name) {
        return this.stack.getTool(name);
    },
    getInput: function(name) {
        return this.stack.getInput(name);
    },
    getFormItem: function(name) {
        return this.stack.getFormItem(name);
    },
    getData: function(name) {
        return this.stack.getData(name);
    },

    // open
    open: function(params) {
        // all popups are closed
        if (!this.isOpen()) {
            this.saved = false;
            this._open(params);
        }
        // current open
        else if (this.isOpen(this.supername)) {
            this.saved = true;
            this.close(false);
        }
        // another is opened
        else {
            this.saved = true;
            this.close(false);
            this._open(params, false);
        }
    },
    openStack: function(name) {
        var stack = this.getStack(name);
        var params = {};

        if (this.stack && this.stack.isCollapsed()) {
            params = { collapse: true };
            this.removeStack(this.stack);
        }

        // open
        stack.open(params);
    },

    // close
    close: function(e, name) {
        if (this.autoclose === false) {
            if (e === true) {}
            else if (!name) {
                return;
            }
        }
        if (!this.isOpen()) return;
        if (e && this._isPopupTarget(e)) return;

        // close
        this._stopEvents();
        this._resetToolbarToggledButton();

        // selection
        if (e !== false && this.saved === false) {
            this.app.scroll.save();
            this.app.selection.restore();
            this.app.scroll.restore();
        }

        this.$popup.hide();
        this._closed();
    },
    closeStacks: function() {
        for (var key in this.stacks) {
            if (typeof this.stacks[key] === 'object') {
                this.stacks[key].close();
            }
        }
    },

    // remove
    removeStack: function(stack) {
        var name = stack.getName();

        // object
        delete this.stacks[name];

        // layer
        this.$popup.find('[data-' + this.prefix + '-stack-name=' + name + ']').remove();
    },

    // update
    updatePosition: function(e) {
        this._buildPosition(e);
        this._buildHeight();
    },

    // resize
    resize: function() {
        var data = this.$popup.attr('data-width');
        var width = this.app.editor.getWidth();
        if (data !== '100%') {
            var w = parseInt(data);
            if (w < width) {
                return;
            }
        }

        this.$popup.css('width', width + 'px');
    },


    // =private

    // build
    _build: function() {
        this.$popup = this.dom('<div>').addClass(this.prefix + '-popup ' + this.prefix + '-popup-' + this.uuid);
        this.$popup.hide();
        //this.$popup.attr('dir', this.opts.editor.direction);

        // append
        this.app.$body.append(this.$popup);
    },
    _buildDepth: function() {
        if (this.opts.bsmodal) {
            this.$popup.css('z-index', 1061);
        }
    },
    _buildButton: function(params) {
        if (!params) return;
        this.button = (Object.prototype.hasOwnProperty.call(params, 'button')) ? params.button : false;
    },
    _buildControl: function(params) {
        if (!params) return;
        this.control = (Object.prototype.hasOwnProperty.call(params, 'control')) ? params.control : false;
    },
    _buildName: function() {
        this.$popup.attr('data-' + this.prefix + '-popup-name', this.name);
        this.$popup.addClass(this.prefix + '-popup-' + this.name);
    },
    _buildHeader: function() {
        this.header = this.app.create('popup.header', this);
    },
    _buildHeight: function() {
        var targetHeight, top;
        var $target = this.app.scroll.getTarget();
        var tolerance = 10;
        var offset = this.$popup.offset();

        if (this.app.scroll.isTarget()) {
            top = offset.top - $target.offset().top;
            targetHeight = $target.height() - parseInt($target.css('border-bottom-width'));
        }
        else {
            top = offset.top - $target.scrollTop();
            targetHeight = $target.height();
        }

        var cropHeight = targetHeight - top - tolerance;
        this.$popup.css('max-height', cropHeight + 'px');
    },
    _buildPosition: function() {
        var topFix = 1;
        var pos;

        // control
        if ((this._isButton() && this.button.isControl()) || this._isControl()) {
            pos = this._buildPositionControl();
        }
        // button
        else if (this._isButton()) {
            pos = this._buildPositionButton();
        }
        // modal
        else {
            pos = this._buildPositionModal();
        }

        // set
        this.$popup.css({
            top: (pos.top - topFix) + 'px',
            left: pos.left + 'px'
        });
    },
    _buildPositionButton: function() {
        var editorRect = this.app.editor.getRect();
        var offset = this.button.getOffset();
        var dim = this.button.getDimension();
        var popupWidth = this.$popup.width();
        var pos = {};
        if (this._isToolbarButton() || this._isTopbarButton()) {
            pos = {
                top: (offset.top + dim.height),
                left: offset.left
            };

            // out of the right edge
            if ((pos.left + popupWidth) > editorRect.right) {
                pos.left = (offset.left + dim.width) - popupWidth;
            }


        }
        else {
            pos = {
                top: (offset.top + editorRect.top + dim.height),
                left: (offset.left + editorRect.left + (dim.width/2) - (popupWidth/2))
            }

            // out of the right edge
            if ((pos.left + popupWidth) > editorRect.right) {
                pos.left = editorRect.left + editorRect.width - popupWidth;
            }

        }

        // out of the left edge
        if (pos.left < editorRect.left || pos.left < 0) {
            pos.left = editorRect.left;
        }

        return pos;

    },
    _buildPositionControl: function() {
        var instance = this.app.block.get();
        if (instance.isSecondLevel()) {
            instance = instance.getFirstLevel();
        }

        var $block = instance.getBlock();
        var offset = $block.offset();

        // set
        return {
            top: offset.top,
            left: offset.left
        };
    },
    _buildPositionModal: function() {
        var offset, top, left;
        if (!this.opts.toolbar) {
            var instance = this.app.block.get();
            if (instance.isSecondLevel()) {
                instance = instance.getFirstLevel();
            }

            var $block = instance.getBlock();
            offset = $block.offset();
            top = offset.top;
            left = offset.left;
        }
        else {
            var $container = this.app.container.get('toolbar');
            var height = $container.height();

            offset = $container.offset();
            top = offset.top + height;
            left = offset.left;
        }


        return { top: top, left: left };
    },

    // get
    _getName: function() {
        return this.$popup.attr('data-' + this.prefix + '-popup-name');
    },

    // set
    _setToolbarToggledButton: function() {
        this.app.toolbar.unsetToggled();
        if (!this._isToolbarButton()) {
            return;
        }

        var name = this.button.getName();
        this.app.toolbar.setToggled(name);
    },

    // create
    _createStack: function(name, params, collapse) {
        if (Object.prototype.hasOwnProperty.call(params, 'collapse') && params.collapse === false) {
            collapse = false;
        }

        if (Object.prototype.hasOwnProperty.call(params, 'autoclose')) {
            this.autoclose = params.autoclose;
        }

        var stack = this.app.create('popup.stack', name, params, collapse, this);
        this.stacks[name] = stack;

        return stack;
    },

    // open
    _open: function(params, animation) {
        this._buildButton(params);
        this._buildControl(params);
        this._buildName();
        this._buildHeader();

        // broadcast
        var event = this.app.broadcast('popup.before.open');
        if (event.isStopped()) {
            this.stopStack();
            return;
        }

        // set & start
        this._setToolbarToggledButton();
        this._startEvents();

        // selection (all popups are closed)
        if (animation !== false && this.app.editor.isPopupSelection()) {
            this.app.selection.save();
        }

        // find active
        this.stack = this._findActiveStack();

        // open stack
        this.stack.open(params, false, false);

        // build position
        this._buildPosition();

        // show
        if (animation === false) {
            this.$popup.show();
            this._opened();
        }
        else {
            this.$popup.fadeIn(100, this._opened.bind(this));
        }
    },
    _opened: function() {
        this._buildHeight();
        this.$popup.addClass('open');

        // broadcast
        this.app.broadcast('popup.open');
        this.stack.renderFocus();
    },

    // closed
    _closed: function() {
        var attrname = 'data-' + this.prefix + '-popup-name';
        var name = this.$popup.attr(attrname);
        this.$popup.removeAttr(attrname);
        this.$popup.removeClass('open ' + this.prefix + '-popup-' + name);
        this.saved = false;

        // broadcast
        this.app.broadcast('popup.close');
    },

    // is
    _isPopupTarget: function(e) {
        return (this.dom(e.target).closest('.' + this.prefix + '-popup').length !== 0);
    },
    _isButton: function() {
        return this.button;
    },
    _isControl: function() {
        return this.control;
    },
    _isToolbarButton: function() {
        return (this.button && (this.button.type === 'toolbar' || this.button.type === 'context'));
    },
    _isTopbarButton: function() {
        return (this.button && this.button.type === 'topbar');
    },


    // find
    _findActiveStack: function() {
        for (var key in this.stacks) {
            if (typeof this.stacks[key] === 'object' && this.stacks[key].isActive()) {
                this.stack = this.stacks[key];
            }
        }

        return this.stack;
    },

    // reset
    _reset: function() {
        this.button = false;
        this.control = false;
        this.autoclose = true;
        this.stack = false;
        this.stacks = [];
        this.$popup.html('');
        this.$popup.removeClass('has-footer has-items has-form');
    },
    _resetToolbarToggledButton: function() {
        if (!this.button) return;
        var name = this.button.getName();
        this.app.toolbar.unsetToggled(name);
    },

    // start
    _startEvents: function() {
        var eventname = this.prefix + '-popup';
        this.app.scroll.getTarget().on('resize.' + eventname + ' scroll.' + eventname, this.updatePosition.bind(this));
    },

    // stop
    _stopEvents: function() {
        this.app.scroll.getTarget().off('.' + this.prefix + '-popup');
    },
    _stop: function() {
        if (this.$popup) this.$popup.remove();
    }
});
Revolvapp.add('class', 'popup.stack', {
    defaults: {
        active: false,
        title: false,
        type: false, // grid
        width: false, // string like '200px' or '100%'
        setter: false,
        getter: false,
        builder: false,
        observer: false,
        instance: false,
        collapse: false,
        form: false,
        items: false,
        focus: false,
        footer: false
    },
    init: function(name, params, collapse, popup) {
        this.defaultWidth = '240px';
        this.popup = popup;
        this.name = name;
        this.tools = {};
        this.data = false;
        this.items = false;
        this.formitems = false;
        this.params = $RE.extend({}, true, this.defaults, params);
        if (collapse) {
            this.params.collapse = true;
        }

        // build
        this._build();
        this._observe();
    },

    // set
    set: function(name, value) {
        this.params[name] = value;
    },
    setData: function(data) {
        this.data = data;
    },
    setFocus: function(name) {
        if (typeof this.tools[name] !== 'undefined') {
            this.tools[name].setFocus();
        }
    },
    setWidth: function(width) {
        var $popup = this.app.popup.getElement();

        $popup.attr('data-width', width);

        if (width === '100%') {
            width = this.app.editor.getWidth() + 'px';
        }

        $popup.css('width', width);
        this.app.$win.on('resize.' + this.prefix + '-popup-' + this.uuid, this.popup.resize.bind(this.popup));
        this.popup.resize();
    },
    setItemsData: function(items) {
        this.items = items;
    },

    // get
    get: function(name) {
        return this.params[name];
    },
    getElement: function() {
        return this.$stack;
    },
    getName: function() {
        return this.name;
    },
    getBody: function() {
        return this.$body;
    },
    getInstance: function() {
        return this.get('instance');
    },
    getItemsData: function() {
        return this.items;
    },
    getItems: function() {
        return this.$items;
    },
    getFooter: function() {
        return this.$footer;
    },
    getFooterPrimary: function() {
        return this.$footer.find('.' + this.prefix + '-form-button-primary');
    },
    getTool: function(name) {
        return (typeof this.tools[name] !== 'undefined') ? this.tools[name] : false;
    },
    getInput: function(name) {
        var tool = this.getTool(name);
        return (tool) ? tool.getInput() : this.dom();
    },
    getFormItem: function(name) {
        var tool = this.getTool(name);

        return (tool) ? tool.getInput().closest('.' + this.prefix + '-form-item') : this.dom();
    },
    getData: function(name) {
        var data;
        if (name) {
            if (typeof this.tools[name] !== 'undefined') {
                data = this.tools[name].getValue();
            }
        }
        else {
            data = {};
            for (var key in this.tools) {
                data[key] = this.tools[key].getValue();
            }
        }

        return data;
    },

    // has
    hasForm: function() {
        return this.formitems;
    },
    hasFooter: function() {
        return (this.footerbuttons !== 0);
    },
    hasItems: function() {
        return (this.items !== false);
    },

    // is
    isCollapsed: function() {
        return this.get('collapse');
    },
    isActive: function() {
        return this.get('active');
    },

    // open
    open: function(params, focus, direct) {
        // input focus
        if (params && params.focus) {
            this.set('focus', params.focus);
        }

        // close stacks
        this.popup.closeStacks();

        // set
        this.app.popup.setStack(this);

        // broadcast
        if (direct !== false) {
            var event = this.app.broadcast('popup.before.open');
            if (event.isStopped()) {
                this.popup.stopStack();
                return;
            }
        }

        // render
        if (params && params.collapse) {
            this._buildItems();
            this._renderItems();
        }
        else {
            this.render();
        }

        // header
        this.popup.header.render(this.popup.stacks);
        this.popup.header.setActive(this);

        // show
        this.$stack.show();
        this._renderWidth();
        if (focus !== false) {
            this.renderFocus();
        }

        // broadcast
        if (direct !== false) {
            this.app.broadcast('popup.open');
        }
    },

    // close
    close: function() {
        this.$stack.hide();
    },
    collapse: function() {
        var prev = this._getPrev();

        if (this.isCollapsed()) {
            this.popup.removeStack(this);
        }

        // open
        prev.open({ collapse: true });
    },

    // render
    render: function() {
        this._renderType();
        this._renderItems();
        this._renderForm();
        this._renderFooter();
        this._renderEnv();
    },
    renderFocus: function() {
        if (this.get('focus')) {
            this.setFocus(this.get('focus'));
        }
    },

    // =private

    // observe
    _observe: function() {
        if (this.params.observer) {
            this.app.api(this.params.observer, this);
        }
    },

    // get
    _getPrev: function() {
        var prev;
        for (var key in this.popup.stacks) {
            if (key === this.name) {
                return prev;
            }
            prev = this.popup.stacks[key];
        }
    },

    // build
    _build: function() {
        this._buildElement();
        this._buildBody();
        this._buildFooter();
        this._buildParams();
    },
    _buildElement: function() {
        this.$stack = this.dom('<div>').addClass(this.prefix + '-popup-stack ' + this.prefix + '-popup-stack-' + this.name);
        this.$stack.hide();
        this.$stack.attr('data-' + this.prefix + '-stack-name', this.name);

        // append
        this.popup.getElement().append(this.$stack);
    },
    _buildBody: function() {
        this.$body = this.dom('<div>').addClass(this.prefix + '-popup-body');
        this.$stack.append(this.$body);
    },
    _buildFooter: function() {
        this.$footer = this.dom('<div>').addClass(this.prefix + '-popup-footer');
        this.$stack.append(this.$footer);
    },
    _buildParams: function() {
        this.params.width = (this.params.width) ? this.params.width : this.defaultWidth;
        this.params.setter = (this.params.setter) ? this.params.setter : false;
        this.params.getter = (this.params.getter) ? this.params.getter : false;
        this.data = (this.params.getter) ? this.app.api(this.params.getter, this) : false;
        this._buildItems();
    },
    _buildItems: function() {
        // items
        if (this.params.builder) {
            this.items = this.app.api(this.params.builder, this);
        }
        else if (this.params.items) {
            this.items = this.params.items;
        }
    },

    // render
    _renderWidth: function() {
        this.setWidth(this.get('width'));
    },
    _renderType: function() {
        this.$stack.removeClass(this.prefix + '-popup-type-grid');

        var type = this.get('type');
        if (type) {
            this.$stack.addClass(this.prefix + '-popup-type-' + type);
        }
    },
    _renderItems: function() {
        if (!this.items) return;

        if (this.$items) {
            this.$items.html('');
        }
        else {
            this.$items = this.dom('<div>').addClass(this.prefix + '-popup-items');
            this.$body.append(this.$items);
        }

        // build items
        for (var name in this.items) {
            if (Object.prototype.hasOwnProperty.call(this.items[name], 'observer') && this.items[name].observer) {
                var res = this.app.api(this.items[name].observer, this.items[name], name, this);
                if (typeof res !== 'undefined') {
                    this.items[name] = res;
                }
            }

            if (this.items[name] === false) continue;

            var item = this.app.create('popup.item', this, name, this.items[name]);
            var $item = item.getElement();

            this._renderItemPosition(this.$items, $item, this.items[name]);
        }
    },
    _renderItemPosition: function($container, $item, params) {
         if (params.position) {
            var pos = params.position;
            if (pos === 'first') {
                $container.prepend($item);
            }
            else if (typeof pos === 'object') {
                var type = (Object.prototype.hasOwnProperty.call(pos, 'after')) ? 'after' : 'before';
                var name = pos[type];
                var $el = this._findPositionElement(name, $container);
                if ($el) {
                    $el[type]($item);
                }
                else {
                    $container.append($item);
                }
            }
        }
        else {
            $container.append($item);
        }
    },
    _renderEnv: function() {
        var $popup = this.popup.getElement();

        $popup.removeClass('has-footer has-items has-form');

        if (this.hasForm()) $popup.addClass('has-form');
        if (this.hasFooter()) $popup.addClass('has-footer');
        if (this.hasItems()) $popup.addClass('has-items');
    },
    _renderForm: function() {
        this.formitems = this.get('form');

        if (!this.formitems) return;

        // build form element
        if (this.$form) {
            this.$form.html('');
        }
        else {
            this.$form = this.dom('<form>').addClass(this.prefix + '-popup-form');
            this.$body.append(this.$form);
            this.$form.on('submit', function() { return false; });

        }

        this._renderTools();
        this._renderData();

        // enter events
        this.$form.find('input[type=text],input[type=url],input[type=email]').on('keydown.' + this.prefix + '-popup', function(e) {
            if (e.which === 13) {
                e.preventDefault();
                this.app.popup.close();
                return false;
            }
        }.bind(this));

    },
    _renderTools: function() {
        for (var name in this.formitems) {
            this._renderTool(name, this.formitems[name]);
        }
    },
    _renderTool: function(name, obj) {
        var tool = this.app.create('tool.' + obj.type, name, obj, this, this.data);
        var $tool = tool.getElement();
        if ($tool) {
            this.tools[name] = tool;
            this.$form.append($tool);
        }
    },
    _renderData: function() {
        if (!this.data) return;
        for (var name in this.data) {
            if (typeof this.tools[name] !== 'undefined') {
                this.tools[name].setValue(this.data[name]);
            }
        }
    },
    _renderFooter: function() {
        this.footerbuttons = 0;
        var buttons = this.get('footer');
        if (!buttons) return;

        this.$footer.html('');

        // buttons
        for (var key in buttons) {
            if (buttons[key] === false) continue;

            var button = this.app.create('popup.button', key, this, buttons[key]);
            this.$footer.append(button.getElement());
            this.footerbuttons++;
        }
    },

    // find
    _findPositionElement: function(name, $container) {
        var $el;
        if (Array.isArray(name)) {
            for (var i = 0; i < name.length; i++) {
                $el = $container.find('[data-name=' + name[i] + ']');
                if ($el.length !== 0) break;
            }
        }
        else {
            $el = $container.find('[data-name=' + name + ']');
        }

        return ($el.length !== 0) ? $el : 0;
    }
});
Revolvapp.add('class', 'popup.header', {
    init: function(popup) {
        this.popup = popup;

        // build
        this._build();
    },
    setActive: function(stack) {
        this.$headerbox.find('.' + this.prefix + '-popup-header-item').removeClass('active');
        this.$headerbox.find('[data-' + this.prefix + '-name=' + stack.getName() + ']').addClass('active');
    },
    render: function(stacks) {
        this._reset();
        var len = this._buildItems(stacks);
        if (len > 0) {
            this._buildClose();
        }
    },

    // private
    _build: function() {
        this.$header = this.dom('<div>').addClass(this.prefix + '-popup-header');
        this.$headerbox = this.dom('<div>').addClass(this.prefix + '-popup-header-box');

        this.$header.append(this.$headerbox);
        this.popup.getElement().prepend(this.$header);
    },
    _buildClose: function() {
        var $close = this.dom('<span>').addClass(this.prefix + '-popup-close');
        $close.one('click', this._catchClose.bind(this));

        this.$header.append($close);
    },
    _buildItems: function(stacks) {
        var len = Object.keys(stacks).length;
        var count = 0;
        var z = 0;
        for (var key in stacks) {
            if (typeof stacks[key] !== 'object') {
                continue;
            }
            z++;
            var title = stacks[key].get('title');
            if (title) {
                count++;
                this._buildItem(stacks[key], title, len);
            }
            else if (z === 1 && len > 1) {
                count++;
                this._buildItem(stacks[key], '## popup.back ##', len);
            }

        }

        return count;
    },
    _buildItem: function(stack, title, len) {
        var isLink = (len > 1);
        var $item = (isLink) ? this.dom('<a>').attr('href', '#') : this.dom('<span>');

        if (isLink) {
            $item.dataset('stack', stack);
            $item.addClass(this.prefix + '-popup-header-item-link');
            $item.on('click', this._catchStack.bind(this));
        }

        $item.attr('data-' + this.prefix + '-name', stack.getName());
        $item.addClass(this.prefix + '-popup-header-item');
        $item.html(this.lang.parse(title));

        this.$headerbox.append($item);
    },
    _reset: function() {
        this.$headerbox.html('');
        this.$header.find('.' + this.prefix + '-popup-close').remove();
    },
    _catchStack: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $item = this.dom(e.target);
        var stack = $item.dataget('stack');
        var current = this.app.popup.getStack();

        // remove collapsable
        if (current.isCollapsed()) {
            this.app.popup.removeStack(current);
        }

        // open
        stack.open();
    },
    _catchClose: function(e) {
        e.preventDefault();
        e.stopPropagation();

        this.popup.close();
    }
});
Revolvapp.add('class', 'popup.button', {
    init: function(name, popup, obj) {

        this.name = name;
        this.obj = obj;
        this.popup = popup;

        this.$button = this.dom('<button>').addClass(this.prefix + '-form-button');
        this.$button.attr('data-name', this.name);
        this.$button.html(this.lang.parse(this.obj.title));
        this.$button.dataset('instance', this);

        if (this._has('type')) this.$button.addClass(this.prefix + '-form-button-' + this.obj.type);
        if (this._has('classname')) this.$button.addClass(this.obj.classname);
        if (this._has('fullwidth')) this.$button.addClass(this.prefix + '-form-button-fullwidth');
        if (this._has('right')) this.$button.addClass(this.prefix + '-form-button-push-right');

        // event
        this.$button.on('click.' + this.prefix + '-popup-button' + this.uuid, this._catch.bind(this));
    },
    getName: function() {
        return this.name;
    },
    getElement: function() {
        return this.$button;
    },
    invokeCommand: function() {
        this._invoke();
    },


    // private
    _has: function(name) {
        return Object.prototype.hasOwnProperty.call(this.obj, name);
    },
    _catch: function(e) {
        e.preventDefault();
        e.stopPropagation();

        if (this._has('command')) {
            this._invoke(e);
        }
        else if (this._has('close')) {
            this.app.popup.close();
        }
    },
    _invoke: function(e) {
        this.app.api(this.obj.command, this.popup, this.name, e);
    }
});
Revolvapp.add('class', 'popup.item', {
    defaults: {
        container: false,
        title: false,
        html: false,
        toggle: true,
        active: false,
        divider: false,
        remover: false,
        classname: false,
        params: false,
        instance: false,
        observer: false,
        command: false
    },
    init: function(popup, name, params) {
        this.popup = popup;
        this.name = name;
        this.params = this._buildParams(params);

        this._build();
        this._buildContainer();
        this._buildIcon();
        this._buildTitle();
        this._buildImage();
        this._buildShortcut();
        this._buildActive();
        this._buildHidden();
        this._buildDivider();
        this._buildCommand();
        this._buildRemover();
    },

    // get
    getPopup: function() {
        return this.popup;
    },
    getName: function() {
        return this.name;
    },
    getParams: function() {
        return this.params.params;
    },
    getElement: function() {
        return this.$item;
    },
    getInstance: function() {
        return this.params.instance;
    },

    // is
    isControl: function() {
        return this.params.control;
    },

    // private
    _build: function() {
        this.$item = (this.params.html) ? this.dom(this.params.html) : this.dom('<div>');
        this.$item.addClass(this.prefix + '-popup-item ' + this.prefix + '-popup-stack-item');
        this.$item.attr({ 'data-name': this.name });
    },
    _buildContainer: function() {
        if (this.params.container) {
            this.$item.addClass(this.prefix + '-popup-item-container');
        }
    },
    _buildTitle: function() {
        if (this.params.title) {
            this.$title = this.dom('<span>').addClass(this.prefix + '-popup-item-title');
            this.$title.html(this.lang.parse(this.params.title));

            this.$item.append(this.$title);
        }
    },
    _buildImage: function() {
        if (this.params.image) {
            this.$image = this.dom('<span>').addClass(this.prefix + '-popup-item-image');
            this.$image.html(this.params.image);

            this.$item.append(this.$image);
        }
    },
    _buildIcon: function() {
        if (this.params.icon) {
            this.$icon = this.dom('<span>').addClass(this.prefix + '-popup-item-icon');

            // html icon
            if (this.opts.buttons.icons && typeof this.opts.buttons.icons[this.name] !== 'undefined') {
                this.$icon.html(this.opts.buttons.icons[this.name]);
            }
            else if (this.params.icon === true) {
                this.$icon.addClass(this.prefix + '-icon-' + this.name);
            }
            else if (this.params.icon.search(/</) !== -1) {
                this.$icon.html(this.params.icon);
            }
            else {
                this.$icon.addClass(this.prefix + '-icon-' + this.params.icon);
            }

            this.$item.append(this.$icon);
        }
    },
    _buildShortcut: function() {
        if (this.params.shortcut) {
            var meta = (/(Mac|iPhone|iPod|iPad)/i.test(navigator.platform)) ? '<b>&#8984;</b>' : 'ctrl';
            meta = this.params.shortcut.replace('Ctrl', meta);

            this.$shortcut = this.dom('<span>').addClass(this.prefix + '-popup-item-shortcut');
            this.$shortcut.html(meta);

            this.$item.append(this.$shortcut);
        }
    },
    _buildParams: function(params) {
        return $RE.extend({}, true, this.defaults, params);
    },
    _buildActive: function() {
       if (this.params.active) {
           this.$item.addClass('active');
       }
    },
    _buildHidden: function() {
        if (this.params.hidden) {
            this.$item.addClass(this.prefix + '-popup-item-hidden');
        }
    },
    _buildDivider: function() {
        if (this.params.divider) {
            this.$item.addClass(this.prefix + '-popup-item-divider-' + this.params.divider);
        }
    },
    _buildCommand: function() {
        if (this.params.command) {
            this.$item.on('click.' + this.prefix + '-popup-item-' + this.uuid, this._catch.bind(this));
            this.$item.attr('data-command', this.params.command);
        }
    },
    _buildRemover: function() {
        if (!this.params.title) return;
        if (this.params.remover) {
           var $trash = this.dom('<span>').addClass(this.prefix + '-popup-item-trash ' + this.prefix + '-icon-trash');
           $trash.attr('data-command', this.params.remover);
           $trash.on('click.' + this.prefix + '-popup-item-' + this.uuid, this._catchRemover.bind(this));

           this.$item.append($trash);
        }
    },
    _catchRemover: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $item = this.dom(e.target).closest('.' + this.prefix + '-popup-stack-item');
        var $trash = this.dom(e.target).closest('.' + this.prefix + '-popup-item-trash');
        var command = $trash.attr('data-command');
        var name = $item.attr('data-name');

        this.app.api(command, this, name);

        $item.fadeOut(200, function($node) {
            $node.remove();
        });
    },
    _catch: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $item = this.dom(e.target).closest('.' + this.prefix + '-popup-stack-item');
        var name = $item.attr('data-name');
        var command = $item.attr('data-command');

        this.popup.$items.find('.' + this.prefix + '-popup-stack-item').removeClass('active');

        if (this.params.toggle) {
            $item.addClass('active');
        }

        // command
        this.app.api(command, this.getParams(), this, name, e);
    }
});

Revolvapp.add('module', 'container', {
    init: function() {
        this.blurclass = this.prefix + '-in-blur';
        this.focusclass = this.prefix + '-in-focus';
    },
    start: function() {
        this._buildMain();
        this._buildContainers(this.$main, this.opts.containers.main);
        this._buildBSModal();
    },
    stop: function() {
        this.$main.remove();
    },
    get: function(name) {
        return this['$' + name];
    },
    setFocus: function() {
        this.$main.removeClass(this.blurclass).addClass(this.focusclass);
    },
    setBlur: function() {
        this.$main.removeClass(this.focusclass).addClass(this.blurclass);
    },
    isFocus: function() {
        return this.$main.hasClass(this.focusclass);
    },

    // private
    _buildMain: function() {
        this.$main = this.dom('<div>').attr(this.prefix + '-uuid', this.uuid);
        this.$main.addClass(this.prefix + '-container ' + this.prefix + '-container-' + this.uuid);

        // place
        this.app.$element.html('');
        this.app.$element.append(this.$main);
    },
    _buildContainers: function($target, containers) {
        for (var i = 0; i < containers.length; i++) {
            var name = containers[i];
            var elName = '$' + name;

            // create
            this[elName] = this._createContainer(name);

            // nested
            if (typeof this.opts.containers[name] !== 'undefined') {
                this._buildContainers(this[elName], this.opts.containers[name]);
            }

            // append
            $target.append(this[elName]);
        }
    },
    _buildBSModal: function() {
        this.opts.bsmodal = (this.$main.closest('.modal-dialog').length !== 0);
    },
    _createContainer: function(name) {
        return this.dom('<div>').addClass(this.prefix + '-' + name + '-container');
    }
});
Revolvapp.add('module', 'source', {
    init: function() {},
    start: function() {
        this._build();
    },
    stop: function() {
        this.$source.off('.' + this.prefix + '-source-events');
        this.$source.remove();
    },
    toggle: function() {
        if (this.app.editor.isSourceMode()) {
            this.close();
        }
        else {
            this.open();
        }
    },
    open: function() {
        this.app.broadcast('source.before.open');

        var html = this.app.editor.getTemplate();
        html = this.app.content.decodeVarsEntities(html);
        html = this.app.tidy.parse(html);
        var height = this.app.container.get('editor').height();

        if (this.opts.editor.viewOnly) {
            this.$source.attr('readonly', true);
        }

        this.$source.height(height);
        this.$source.val(html);
        this.$source.on('input.' + this.prefix + '-source-events', this._handleChanges.bind(this));
        this.$source.on('keydown.' + this.prefix + '-source-events', this.app.input.handleTextareaTab.bind(this));

        this.app.container.get('editor').hide();
        this.app.container.get('source').show();

        // ui
        this.app.popup.close();
        this.app.control.close();
        this.app.path.disable();
        this.app.toolbar.setToggled('code');
        this.app.toolbar.disableButtons(['code']);

        // broadcast
        this.app.broadcast('source.open');
    },
    close: function() {
        this.app.broadcast('source.before.close');
        var html = this.$source.val();

        this.app.editor.setTemplate(html);

        this.$source.off('.' + this.prefix + '-source-events');

        this.app.container.get('source').hide();
        this.app.container.get('editor').show();

        // ui
        this.app.path.enable();
        this.app.toolbar.unsetToggled('code');
        this.app.toolbar.enableButtons();

        // broadcast
        this.app.broadcast('source.close');
    },
    checkCodeView: function(obj) {
        return (this.opts.source) ? obj : false;
    },

    // private
    _build: function() {
        this.$source = this.dom('<textarea>');
        this.$source.addClass(this.prefix + '-source');
        this.$source.attr('data-gramm_editor', false);

        this.app.container.get('source').append(this.$source);
    },
    _handleChanges: function(e) {
        this.app.broadcast('source.change', { e: e });
    }
});
Revolvapp.add('module', 'toolbar', {
    subscribe: {
        'editor.load': function() {
            this.build();
        }
    },
    init: function() {
        this.eventname = this.prefix + '-toolbar';
        this.activeClass = 'active';
        this.toggledClass = 'toggled';
        this.disableClass = 'disable';
        this.customButtons = {};
    },
    start: function() {
        this._build();
        this._buildSticky();
    },
    stop: function() {
        this.$toolbar.remove();
        this.customButtons = {};
    },
    // compatibility 2.2.0
    rebuild: function() {
        this.build();
    },
    build: function() {
        this.$toolbar.html('');
        this._buildButtons();

        if (this.opts.editor.viewOnly) {
            this.removeAll(['mobile', 'code']);
        }
    },

    // public
    isSticky: function() {
        var $toolbar = this.app.container.get('toolbar');
        var $main = this.app.container.get('main');

        return ($main.offset().top < $toolbar.offset().top);
    },
    getElement: function() {
        return this.$toolbar;
    },
    get: function(name) {
        return this._findButton(name);
    },
    add: function(name, obj) {
        this.customButtons[name] = obj;
    },
    remove: function(name) {
        this._findButton(name).remove();
    },
    removeAll: function(except) {
        this._findButtons().each(function($btn) {
            var btnName = $btn.attr('data-name');

            if (except.indexOf(btnName) === -1) {
                $btn.remove();
            }

        }.bind(this));
    },

    setActive: function(name) {
        if (!this.opts.toolbar) return;
        this._findButtons().removeClass(this.activeClass);
        this._findButton(name).removeClass(this.disableClass).addClass(this.activeClass);
    },
    setToggled: function(name) {
        if (!this.opts.toolbar) return;
        this._findButtons().removeClass(this.toggledClass);
        this._findButton(name).removeClass(this.disableClass).addClass(this.toggledClass);
    },
    unsetActive: function(name) {
        if (!this.opts.toolbar) return;
        var $elms = (name) ? this._findButton(name) : this._findButtons();
        $elms.removeClass(this.activeClass);

    },
    unsetToggled: function(name) {
        if (!this.opts.toolbar) return;
        var $elms = (name) ? this._findButton(name) : this._findButtons();
        $elms.removeClass(this.toggledClass);
    },
    disableButtons: function(except) {
        this._findButtons().each(function($btn) {
            var btnName = $btn.attr('data-name');

            if (except.indexOf(btnName) === -1) {
                $btn.addClass(this.disableClass);
            }

        }.bind(this));
    },
    enableButtons: function() {
        this._findButtons().removeClass(this.disableClass);
    },

    // private
    _build: function() {
        this.$toolbar = this.dom('<div>').addClass(this.prefix + '-toolbar');
        var $container = this.app.container.get('toolbar');
        $container.append(this.$toolbar);
        $container.on('mouseover.' + this.prefix, this._buildHover.bind(this));
    },
    _buildHover: function() {
        this.app.editor.unsetHover();
    },
    _buildSticky: function() {
        if (this.opts.toolbar.sticky) {
            var $container = this.app.container.get('toolbar');
            $container.addClass(this.prefix + '-toolbar-sticky');
            $container.css('top', this.opts.toolbar.stickyTopOffset + 'px');

            if (this.app.scroll.isTarget()) {
                var $scrollTarget = this.app.scroll.getTarget();
                $scrollTarget.on('scroll.revolvapp-toolbar', this._observeSticky.bind(this));
            }
        }
    },
    _buildButtons: function() {
        var instance = (this.app.component.is()) ? this.app.component.get() : this.app.editor.getBodyInstance();
        var buttons = instance.toolbar;

        for (var name in buttons) {
            if (instance.isAllowedButton(buttons[name])) {
                this.app.create('button', name, buttons[name], this.$toolbar, 'toolbar');
            }
        }

        // custom buttons
        for (var cname in this.customButtons) {
            if (instance.isAllowedButton(this.customButtons[cname])) {
                this.app.create('button', cname, this.customButtons[cname], this.$toolbar, 'toolbar');
            }
        }
    },
    _observeSticky: function() {
        var $scrollTarget = this.app.scroll.getTarget();
        var $container = this.app.container.get('toolbar');
        var paddingTop = parseInt($scrollTarget.css('padding-top'));

        $container.css('top', (0 - paddingTop + this.opts.toolbar.stickyTopOffset) + 'px');
    },
    _findButtons: function() {
        return this.$toolbar.find('.rex-button-toolbar');
    },
    _findButton: function(name) {
        return this.$toolbar.find('[data-name=' + name + ']');
    }
});
Revolvapp.add('module', 'path', {
    subscribe: {
        'editor.load': function() {
            this.build();
        }
    },
    init: function() {
        // local
        this.activeClass = 'active';
        this.disableClass = 'disable';
    },
    start: function() {
        this._build();
    },
    stop: function() {
        this.$path.remove();
    },
    build: function() {
        if (this.opts.editor.viewOnly) return;
        this.$path.html('');

        var bodyInstance = this.app.editor.getBodyInstance();
        if (this.app.component.is()) {
            var instance = this.app.component.get();
            this._buildBodyItem(bodyInstance);
            this._buildParents(instance);
            this._buildCurrent(instance);
        }
        else {
            this._buildBodyItem(bodyInstance);
        }

        this._setLastActive();
    },
    get: function() {
        return this.$path;
    },
    enable: function() {
        this._findItems().removeClass(this.disableClass);
    },
    disable: function() {
        this._findItems().addClass(this.disableClass);
    },

    // private
    _createItem: function(instance) {
        var title = this.app.lang.parse(instance.getTitle());
        var $item = this.dom('<a>').attr('href', '#').html(title).addClass(this.prefix + '-path-item');
        $item.dataset('instance', instance);
        $item.on('click.' + this.prefix + '-path', this._catch.bind(this));

        return $item;
    },
    _buildParents: function(instance) {
        var el = instance.getElement();
        var $parents = this.app.element.getParents(el, this.opts._elements);
        $parents.nodes.reverse();
        $parents.each(this._buildParentItem.bind(this));
    },
    _buildParentItem: function($node) {
        var instance = $node.dataget('instance');
        var $item = this._createItem(instance);
        this.$path.append($item);
    },
    _buildBodyItem: function(instance) {
        var $item = this._createItem(instance);
        $item.attr('data-body', true);
        this.$path.append($item);
    },
    _buildCurrent: function(instance) {
        var $item = this._createItem(instance);
        this.$path.append($item);
    },
    _build: function() {
        this.$path = this.dom('<div>').addClass(this.prefix + '-path');
        this.app.container.get('toolbar').append(this.$path);
    },
    _findItems: function() {
        return this.$path.find('.' + this.prefix + '-path-item');
    },
    _setLastActive: function() {
        this._findItems().last().addClass(this.activeClass);
    },
    _catch: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $item = this.dom(e.target);
        if ($item.hasClass(this.disableClass)) return;

        var instance = $item.dataget('instance');
        var body = $item.attr('data-body');

        if (body) {
            this.app.component.unset();
        }
        else {
            this.app.component.set(instance.getElement());
        }
    }
});
Revolvapp.add('module', 'control', {
    init: function() {
        // local
        this.instance = false;
        this.customButtons = {};
    },
    start: function() {
        this._build();
    },
    stop: function() {
        this.$control.remove();
        this.instance = false;
        this.customButtons = {};
    },
    isOpen: function() {
        return (this.$control.css('display') !== 'none');
    },
    getElement: function() {
        return this.$control;
    },
    get: function(name) {
        return this._findButton(name);
    },
    add: function(name, obj) {
        this.customButtons[name] = obj;
    },
    remove: function(name) {
        this._findButton(name).remove();
    },
    open: function(instance) {
        this.$control.html('');

        this.instance = instance;
        var buttonsLen = this._buildButtons();

        if (buttonsLen > 0) {
            var $scrollTarget = this.app.scroll.getTarget();

            this.updatePosition();
            $scrollTarget.on('resize.revolvapp-control', this.updatePosition.bind(this));
            $scrollTarget.on('scroll.revolvapp-control', this.updatePosition.bind(this));
            this.app.editor.getWin().on('scroll.revolvapp-control', this.updatePosition.bind(this));
            this.$control.show();
            this.updatePosition();
        }
        else {
            this.close();
        }
    },
    close: function() {
        this.$control.hide();
        this.instance = false;

        var $scrollTarget = this.app.scroll.getTarget();
        $scrollTarget.off('.revolvapp-control');
    },
    updatePosition: function() {
        if (!this.instance) {
            return;
        }

        var offset = this.instance.getOffset();
        var width = this.$control.width();
        var scrollTop = this.app.editor.getWin().scrollTop();
        var topOutlineFix = 2;
        var leftOutlineFix = 3;
        var top = (offset.top - topOutlineFix - scrollTop);
        var $toolbar = this.app.toolbar.getElement();
        var toolbarBottom = ($toolbar.offset().top + $toolbar.height()) - topOutlineFix;
        var frameRect = this.app.editor.getFrameRect();

        if (top < toolbarBottom || frameRect.bottom < top) {
            this.$control.hide();
        }
        else {
            this.$control.show();
        }

        // position
        this.$control.css({
            top: top + 'px',
            left: (offset.left - width - leftOutlineFix) + 'px'
        });
    },

    // private
    _buildButtons: function() {
        var buttons = this.instance.control;
        var count = 0;

        for (var name in buttons) {
            // unremovable
            if (name === 'trash' && this.instance.isUnremovable()) {
                continue;
            }

            // allowed
            if (this.instance.isAllowedButton(buttons[name])) {
                this.app.create('button', name, buttons[name], this.$control, 'control');
                count++;
            }
        }

        // custom buttons
        for (var cname in this.customButtons) {
            if (this.instance.isAllowedButton(this.customButtons[cname])) {
                this.app.create('button', cname, this.customButtons[cname], this.$control, 'control');
                count++;
            }
        }

        return count;
    },
    _build: function() {

        // block & element
        this.$control = this.dom('<div>');
        this.$control.addClass(this.prefix + '-control');
        this.$control.hide();

        // bs modal
        if (this.opts.bsmodal) {
            this.$control.css('z-index', 1060);
        }

        this.app.$body.append(this.$control);
    },
    _findButton: function(name) {
        return this.$control.find('[data-name=' + name + ']');
    }
});
Revolvapp.add('module', 'observer', {
    init: function() {
        this.observer = false;
        this.trigger = true;
    },
    stop: function() {
        if (this.observer) this.observer.disconnect();
        this.trigger = true;
    },
    build: function() {
        this.stop();

        if (window.MutationObserver) {
            var el = this.app.editor.$template.get();
            this.observer = this._build(el);
            this.observer.observe(el, {
                 attributes: true,
                 subtree: true,
                 childList: true,
                 characterData: true,
                 characterDataOldValue: true
            });
        }
    },
    sync: function(el) {
        this._sync(el, false);
    },

    // private
    _build: function(el) {
        var self = this;
        return new MutationObserver(function(mutations) {
            self._observe(mutations[mutations.length-1], el);
        });
    },
    _observe: function(mutation, el) {
        if (!this.trigger) return;

        if ((mutation.type === 'attributes' && mutation.target === el) || this.app.state.is()) {
            return;
        }

        var is = this.app.component.is();
        var instance = this.app.component.get();
        var editable = (mutation.type === 'childList' && is && instance.isEditable());

        // sync
        this._sync(el, editable);
    },
    _sync: function(el, editable) {
        var delay = (editable) ? 300 : 0;

        if (this.timeout) clearTimeout(this.timeout);
        this.timeout = setTimeout(function() {
            this.app.state.add(el, editable);
            this.app.autosave.send();
        }.bind(this), delay);

        this.app.broadcast('editor.change');
    }
});
Revolvapp.add('module', 'component', {
    init: function() {
        this.instance = false;
        this.items = this.app.create('component.items');
        this.popups = this.app.create('component.popups');
    },
    set: function($el, force, callEvent, focus) {
        var instance = $el.dataget('instance');
        if (force !== true && this._isActive($el) && !instance.isEditable() && !this.app.popup.isOpen()) {
            this.unset();
            return;
        }

        this.app.editor.unset();

        // set active
        this._setActiveInstance(instance);
        this._setActiveClass();
        this._setSourceActive();
        if (focus !== false) this.focus();

        // ui
        this.app.toolbar.build();
        this.app.path.build();
        this.app.control.open(instance);
        this.app.popup.close();

        // broadcast
        if (callEvent !== false) {
            this.app.broadcast('component.set');
        }
    },
    unset: function() {
        if (this.instance === false) {
            return;
        }

        this.app.editor.unset();

        this._unsetActiveClass();
        this._unsetSourceActive();

        this.instance = false;

        // ui
        this.app.popup.close();
        this.app.control.close();
        this.app.toolbar.build();
        this.app.path.build();

        // broadcast
        this.app.broadcast('component.unset');
    },
    is: function($el) {
        return ($el) ? this._isActive($el) : this.get();
    },
    get: function() {
        return this.instance;
    },
    observe: function(obj, name) {
        var res = obj;
        if (name === 'background') {
            obj.background = this.get().getData('background-color');
        }
        else if (name === 'text-color') {
            var instance = this.get();
            var text = (instance.isType('block') || instance.isType('column')) ? instance.getElements(['text']).length : true;

            if (text !== 0) {
                obj.background = instance.getData('color');
            }
            else {
                res = false;
            }
        }

        return res;
    },
    focus: function() {
        var instance = this.get();
        if (!instance) {
            return;
        }

        if (instance.isEditable()) {
            var $target = instance.getEditableElement();
            $target.focus();
            return;
        }

        var $span = this.dom('<span>').attr('contenteditable', true);
        $span.css({ width: 0, height: 0, display: 'block' });
        instance.getElement().before($span);
        $span.focus();
        $span.remove();
    },
    popup: function(params, button, name) {
        this.popups.open(button, name);
    },
    openAdd: function(params, button) {
        this.popups.add(button);
    },

    // actions
    duplicate: function() {
        var instance = this.get();

        if (instance.isLayer() || instance.isType('column')) {
            return;
        }

        var $source = instance.getSource();
        var $clone = $source.clone();

        $clone.removeAttr('unremovable');
        $source.after($clone);

        var newInstance = this.app.create('tag.' + instance.getType(), $clone);
        newInstance.renderNodes();

        var $el = newInstance.getElement();
        instance.getElement().after($el);

        this.set($el);
        this.app.editor.rebuild();

        // event
        this.app.broadcast('component.duplicate');
    },
    remove: function() {
        var instance = this.get();
        if (instance.isLayer() || instance.isUnremovable()) {
            return;
        }

        var block = instance.getParent('block');
        var column = instance.getParent('column');
        var grid = instance.getParent('grid');
        var next = instance.getNext();
        if (next && next.isType('column-spacer')) {
            next = next.getNext();
        }

        var type = instance.getType();

        instance.remove();
        this.unset();
        this.app.editor.rebuild();
        this._traverseRemove(block, column, grid, type, next);
    },
    drop: function(e, dt) {
        if (!this.opts.image || !this.opts.image.upload) return;

        var $el = this.dom(e.target).closest('[data-' + this.prefix + '-type=image]');
        var instance = ($el.length !== 0) ? $el.dataget('instance') : false;
        if (!instance) return;

        this.set($el, true, false);

        var files = [];
        for (var i = 0; i < dt.files.length; i++) {
            var file = dt.files[i] || dt.items[i].getAsFile();
            if (file) {
                files.push(file);
            }
        }

        var params = {
            url: this.opts.image.upload,
            name: this.opts.image.name,
            data: this.opts.image.data,
            multiple: this.opts.image.multiple,
            success: 'image.successDropUpload',
            error: 'image.error'
        };

        var upload = this.app.create('upload');
        upload.send(e, files, params);

    },
    sync: function() {
        var instance = this.get();
        if (instance.isEditable()) {
            instance.sync();
            this.app.editor.adjustHeight();
        }
    },
    insert: function(html, caret) {
        var instance = this.get();
        if (!instance || !instance.isEditable()) return;

        var inserted = this.app.insertion.insertNode(html, caret);
        instance.sync();

        return inserted;
    },
    paste: function(e) {
        e.preventDefault();
        this.app.content.paste(e);
        this.get().sync();
    },
    moveUp: function(context, e) {
        var instance = this.get();
        var prev = instance.getPrev();

        if (prev && !instance.isLayer()) {

            e.preventDefault();

            var $el = instance.getElement();
            var $source = instance.getSource();

            var $prevEl = prev.getElement();
            var $prevSource = prev.getSource();

            $prevEl.before($el);
            $prevSource.before($source);

            this.app.control.updatePosition();
        }
    },
    moveDown: function(context, e) {
        var instance = this.get();
        var next = instance.getNext();

        if (next && !instance.isLayer()) {
            e.preventDefault();

            var $el = instance.getElement();
            var $source = instance.getSource();

            var $nextEl = next.getElement();
            var $nextSource = next.getSource();

            $nextEl.after($el);
            $nextSource.after($source);

            this.app.control.updatePosition();
        }
    },
    replaceSource: function(code) {
        var instance = this.get();
        var type = instance.getType();
        var newInstance = this.app.create('tag.' + type, code);
        var $el = newInstance.getElement();

        newInstance.renderNodes();
        instance.getElement().after($el);
        instance.getSource().after(newInstance.getSource());
        instance.remove();

        this.set($el);
        this.app.editor.rebuild();

    },

    // getter & setter
    getData: function() {
        var instance = this.get();
        var data = instance.getData();

        return data;
    },
    setData: function(stack) {
        var button = this.app.popup.getButton();
        var data = stack.getData();
        var instance = this.get();

        instance.setData(data);
        button.setColor(stack, data);

        this.triggerData(data);
    },
    triggerData: function(data) {
        this.app.control.updatePosition();
        this.app.editor.adjustHeight();

        // event
        this.app.broadcast('component.change', { data: data });
    },

    // check
    checkImageChange: function(obj) {
        if (!this.app.editor.isImageChange()) {
            return;
        }

        return obj;
    },
    checkColumnSpacer: function(obj) {
        return (this.get().getElements(['column-spacer']).length !== 0) ? obj : false;
    },
    checkValign: function(obj) {
        var types = ['block', 'column'];
        var instance = this.get();
        var type = instance.getType();

        return (types.indexOf(type) === -1) ? false : obj;
    },

    // add block
    add: function(e, html) {
        var newInstance;
        if (e) {
            e.preventDefault();
            e.stopPropagation();

            var $item = this.dom(e.target).closest('.' + this.prefix + '-popup-section-item');
            var type = $item.attr('data-type');
            newInstance = this.app.create('block.' + type);
        }
        else {
            newInstance = this.app.create('tag.block', html);
            newInstance.renderNodes();
        }

        var instance = this.get();
        var mode = (instance) ? 'block' : 'button';

        // element mode
        if (instance && !instance.isType('block') && !instance.isLayer()) {
            mode = 'element';
        }
        // add button instance
        else if (mode === 'button') {
            instance = this._getAddInstance();
        }

        var $source = instance.getSource();
        var $target = instance.getTarget();
        var $element = instance.getElement();
        var $blockSource = newInstance.getSource();
        var $blockElement = newInstance.getElement();

        if (mode === 'element') {
            // add as elements via addbar
            var $first;
            var $elms = $blockSource.children();
            $elms.nodes.reverse();
            $elms.each(function($node) {
                var node = $node.get();
                var tag = node.tagName.toLowerCase();
                var newEl = this.app.create('tag.' + tag.replace('re-', ''), $node);
                newEl.renderNodes();

                var $newEl = newEl.getElement();
                $element.after($newEl);
                $source.after(newEl.getSource());

                $first = $newEl;
            }.bind(this));

            // set
            this._setAddInstance($first);
            return;
        }
        else if (mode === 'block') {
            // add as block via addbar
            var func = (instance.isLayer()) ? 'append' : 'after';

            $source[func]($blockSource);

            if (instance.isLayer()) {
                $target[func]($blockElement);
            }
            else {
                $element[func]($blockElement);
            }
        }
        else {
            // add by add button
            $target.removeClass(this.prefix + '-empty-layer').html('');

            $target.append($blockElement);
            $source.append($blockSource);
        }

        // set
        this._setAddInstance($blockElement);
    },
    buildAddItems: function(stack) {

        for (var key in this.opts._blocks) {
            var $section = this.dom('<div>').addClass(this.prefix + '-popup-section');
            var $sectionBox = this.dom('<div>').addClass(this.prefix + '-popup-section-box');

            var sectionTitle = this.lang.get('add-sections.' + key);
            $section.html(sectionTitle || key);

            // items
            var items = this.opts._blocks[key];
            for (var index in items) {

                if (this._isHiddenBlock(items[index].type)) {
                    continue;
                }

                var $item = this.dom('<span>').addClass(this.prefix + '-popup-section-item');
                $item.attr('data-type', items[index].type);

                if (items[index].icon) {
                    $item.html(items[index].icon);
                }
                else {
                    var $blockmap = this.dom('<div>').addClass(this.prefix + '-popup-block-map ' + this.prefix + '-b-map-' + items[index].type);
                    $item.append($blockmap);
                }

                var $title = this.dom('<span>').html(items[index].title);
                $item.append($title);
                $sectionBox.append($item);

                $item.on('click.revolvapp', this.add.bind(this));
            }

            if ($sectionBox.html() !== '') {
                stack.$body.append($section);
                stack.$body.append($sectionBox);
            }
        }
    },

    // private
    _isActive: function($el) {
        return (this.instance && ($el.get() === this.get().$element.get()));
    },
    _isHiddenBlock: function(type) {
        return (this.opts.blocks.hidden && this.opts.blocks.hidden.indexOf(type) !== -1);
    },
    _setActiveClass: function() {
        var instance = this.get();
        instance.getElement().addClass(this.prefix + '-element-active');
    },
    _setActiveInstance: function(instance) {
        this.instance = instance;
    },
    _setSourceActive: function() {
        this.get().getSource().attr('active', true);
    },
    _unsetActiveClass: function() {
        var instance = this.get();
        instance.getElement().removeClass(this.prefix + '-element-active');
    },
    _unsetSourceActive: function() {
        this.get().getSource().removeAttr('active');
    },
    _setAddInstance: function($el) {
        this.app.popup.close();
        this.set($el);
        this.app.editor.rebuild();
        this.app.element.scrollTo($el);

        // event
        this.app.broadcast('component.add');
    },
    _getAddInstance: function() {
        var types = ['main', 'header', 'footer'];
        var button = this.app.popup.getButton();
        var $el = button.getElement();
        var $layer = this.app.element.getClosest($el, types);

        return $layer.dataget('instance');
    },
    _traverseRemove: function(block, column, grid, type, next) {
        if (type === 'block') {
            if (next) {
                this.set(next.getElement());
            }
        }
        else if (type === 'column') {
            if (next) {
                this.set(next.getElement());
            }
            else {
                if (grid.isEmpty()) {
                    block = grid.getNext();
                    grid.remove();

                    if (block) {
                        this.set(block.getElement());
                    }
                }
            }
        }
        else {
            if (next) {
                this.set(next.getElement());
            }
            else {
                if (column) {
                    this.set(column.getElement());
                }
                else if (block) {
                    if (block.isEmpty()) {
                        next = block.getNext();
                        block.remove();
                        if (next) {
                            this.set(next.getElement());
                        }
                    }
                    else {
                        this.set(block.getElement());
                    }
                }
            }
        }
    }
});
Revolvapp.add('class', 'component.items', {
    init: function() {
        this.instance = false;
    },
    reset: function() {
        this.instance = false;
    },
    get: function() {
        return this.instance;
    },
    getItemData: function() {
        if (this.instance) {
            var data = this.instance.getData();

            return data;
        }
    },
    setItemData: function(stack) {
        var data = stack.getData();
        var instance = stack.getInstance();

        instance.setData(data);
        this.app.component.triggerData(data);
    },
    build: function() {
        this.reset();

        var items = {};
        var $items = this.app.component.get().getItems();
        $items.each(function($node, i) {
            var instance = $node.dataget('instance');
            var name = $node.html();
            if (instance.getType() === 'social-item') {
                name = '<span class="' + this.prefix + '-popup-item-image">' + name + '</span>';
            }

            items[i] = {
                title: name,
                command: 'component.items.edit',
                remover: 'component.items.remove',
                instance: instance,
                close: false
            };
        }.bind(this));

        return items;
    },
    edit: function(params, item) {
        this.instance = item.getInstance();
        this.app.component.popups.edititem(item);
    },
    add: function(stack) {
        this.reset();

        var data = stack.getData();
        var instance = this.app.component.get();
        var $spacerEl = instance.getSpacers().first();
        var $itemEl = instance.getItems().first();
        var type = (instance.isType('social')) ? 'social' : 'menu';
        var $itemSource = ($itemEl.length !== 0) ? $itemEl.dataget('instance').getSource().clone() : false;
        var $spacerSource = ($spacerEl.length !== 0) ? $spacerEl.dataget('instance').getSource().clone() : false;

        if (instance.isType('social')) {
            if (data.image === '') return;
            if (!$itemSource) {
                $itemSource = this.dom('<re-image>');
            }

            $itemSource.attr({ 'placeholder': false, 'src': data.image });
        }
        else if (data.html === '') {
            return;
        }

        var item = this.app.create('tag.' + type + '-item', $itemSource);
        var spacer = this.app.create('tag.' + type + '-spacer', $spacerSource);

        if ($spacerSource === false) {
            spacer.setData({ 'html': '&nbsp;&nbsp;' });
        }

        if ($itemEl.length !== 0) {
            instance.add(spacer);
        }

        instance.add(item);

        // set
        item.setData(data);
        stack.collapse();
    },
    remove: function(stack) {
        var itemInstance = stack.getInstance();
        itemInstance.removeItem();
    }
});
Revolvapp.add('class', 'component.popups', {
    init: function() {},
    open: function(button, name) {
        if (name === 'text-color') this.textcolor(button);
        else if (name === 'background') this.background(button);
        else if (name === 'alignment') this.alignment(button);
        else if (name === 'border') this.border(button);
        else if (name === 'tune') this.settings(button);
        else if (name === 'items') this.items(button);
        else if (name === 'add') this.add(button);
        else if (name === 'image') this.image(button);
    },
    image: function(button) {
        var instance = this.app.component.get();
        this.app.popup.create('image', {
            width: '320px',
            title: instance.getTitle(),
            instance: instance,
            getter: 'component.getData',
            setter: 'component.setData',
            form: instance.forms.image
        });

        // open
        this.app.popup.open({ button: button });
    },
    items: function(button) {
        this.app.popup.create('items', {
            width: '300px',
            builder: 'component.items.build',
            footer: {
                add: { title: '## buttons.add-item ##', fullwidth: true, command: 'component.popups.additem', type: 'primary' },
            }
        });

        this.app.popup.open({ button: button });
    },
    additem: function() {
        var component = this.app.component.get();

        // stack
        var stack = this.app.popup.add('add-item', {
            width: '320px',
            title: '## popup.add-item ##',
            form: component.forms.item,
            footer: {
                add: { title: '## buttons.add ##', command: 'component.items.add', type: 'primary' },
                cancel: { title: '## buttons.cancel ##', collapse: true }
            }
        });

        // open stack
        stack.open();

        // focus
        if (component.isType('menu')) {
            stack.setFocus('html');
        }
    },
    edititem: function(item) {
        var component = this.app.component.get();
        var instance = item.getInstance();
        var stack = this.app.popup.add('edit-item', {
            width: '320px',
            title: '## popup.edit-item ##',
            instance: instance,
            getter: 'component.items.getItemData',
            setter: 'component.items.setItemData',
            form: component.forms.item
        });

        stack.open();
    },
    add: function(button) {
        this._unsetComponent(button);

        this.app.popup.create('add', {
            width: '600px',
            title: '## editor.add-block ##',
            builder: 'component.buildAddItems'
        });

        this.app.popup.open({ button: button });
    },
    textcolor: function(button) {
        var names = ['block', 'column', 'text'];
        var instance = this.app.component.get();

        this.app.popup.create('text-color', {
            title: '## popup.text-color ##',
            width: '320px',
            getter: 'component.getData',
            setter: 'component.setData',
            form: this.opts.forms.textcolor
        });

        if (names.indexOf(instance.getType()) !== -1) {
            this.app.popup.add('link-color', {
                collapse: false,
                title: '## popup.link-color ##',
                width: '320px',
                getter: 'component.getData',
                setter: 'component.setData',
                form: this.opts.forms.linkcolor
            });
        }

        this.app.popup.open({ button: button });
    },
    background: function(button) {
        var names = ['block', 'column', 'main', 'header', 'footer'];
        var instance = this.app.component.get();

        this.app.popup.create('background', {
            title: '## popup.background ##',
            width: '320px',
            getter: 'component.getData',
            setter: 'component.setData',
            form: this.opts.forms.background
        });

        if (names.indexOf(instance.getType()) !== -1 && this.app.editor.isImageChange()) {
            this.app.popup.add('background-image', {
                collapse: false,
                width: '320px',
                title: '## popup.background-image ##',
                instance: instance,
                getter: 'component.getData',
                setter: 'component.setData',
                form: this.opts.forms.backgroundimage
            });
        }

        this.app.popup.open({ button: button });
    },
    alignment: function(button) {
        this.app.popup.create('alignment', {
            getter: 'component.getData',
            setter: 'component.setData',
            form: this.opts.forms.alignment
        });
        this.app.popup.open({ button: button });
    },
    border: function(button) {
        this.app.popup.create('border', {
            title: '## popup.border ##',
            getter: 'component.getData',
            setter: 'component.setData',
            form: this.opts.forms.border
        });
        this.app.popup.open({ button: button });
    },
    settings: function(button) {
        var instance = this.app.component.get();
        var title = (instance.isType('image')) ? this.lang.get('popup.settings') : instance.getTitle();
        this.app.popup.create('settings', {
            width: '320px',
            title: title,
            instance: instance,
            getter: 'component.getData',
            setter: 'component.setData',
            form: instance.forms.settings
        });

        // open
        this.app.popup.open({ button: button });
    },

    // private
    _unsetComponent: function(button) {
        if (button.getName() === 'addempty') {
            this.app.component.unset();
        }
    }
});
Revolvapp.add('module', 'editor', {
    init: function() {
        // local
        this.cssfile = 'css/revolvapp-frame.min.css?' + new Date().getTime();
        this.$template = null;
        this.$templateSource = null;
        this.$elements = [];
        this.mobileMode = false;
        this.stateLoad = false;
        this.popups = this.app.create('editor.popups');
    },
    start: function() {
        // build
        this._build();

        // build template
        if (this.opts.editor.template) {
            this._buildTemplate();
        }
        else {
            var template = (this.opts.content) ? this.opts.content : this.app._elementContent.trim();
            if (template && template !== '') {
                this._buildContent(template);
            }
        }

        // options
        this._buildOptions();
        this._buildBlocksOpts();
    },
    stop: function() {
        this.app.$element.show();
    },
    rebuild: function() {
        this._buildElements();

        if (this.opts.editor.viewOnly) {
            this.app.event.buildPreventLinks();
        }
        else {
            this.app.event.build();
        }

        this.buildEmptyLayers();
        this.adjustHeight();

        // event
        var offset = this.stateLoad;
        if (this.stateLoad === false) {
            this.app.broadcast('editor.rebuild');
        }
        else {
            this.$elements.each(function($node) {
                var instance = $node.dataget('instance');
                if (instance.isActiveSource()) {
                    this.app.component.set($node);

                    // offset
                    if (typeof offset === 'object') {
                        instance = this.app.component.get();
                        var $el = instance.getElement();
                        this.app.offset.set($el, offset);
                    }
                }

            }.bind(this));
        }

        this.stateLoad = false;
    },
    insertContent: function(obj) {
        if (obj.html) {
            this.app.component.add(false, obj.html);
        }
    },
    setTemplate: function(template) {
        // event
        var event = this.app.broadcast('editor.before.set', { template: template });
        template = event.get('template');

        this._buildContent(template);

        // ui
        this.app.component.unset();

        // broadcast
        this.app.broadcast('editor.change');
    },
    setTemplateElement: function($el) {
        this.$template = $el;
    },
    setState: function(template, offset) {
        this.stateLoad = (offset === false) ? true : offset;
        this._buildTemplateSource(template);
        this.app.parser.parse();
    },
    setFocus: function() {

    },
    setWinFocus: function() {
        this.getWin().focus();
    },
    getWidth: function() {
        var $editor = this.getEditor();
        var padLeft = parseInt($editor.css('padding-left'));
        var padRight = parseInt($editor.css('padding-right'));

        return ($editor.width() - padLeft - padRight);
    },
    getEditor: function() {
        return this.getFrame();
    },
    getLayout: function() {
        return this.getFrame();
    },
    getFrame: function() {
        return this.$editor;
    },
    getDoc: function() {
        return this.dom(this.$editor.get().contentWindow.document);
    },
    getWin: function() {
        return this.dom(this.$editor.get().contentWindow);
    },
    getDocNode: function() {
        return this.$editor.get().contentWindow.document;
    },
    getWinNode: function() {
        return this.$editor.get().contentWindow;
    },
    getHead: function() {
        return this.getDoc().find('head');
    },
    getBody: function() {
        return this.getDoc().find('body');
    },
    getBodyTarget: function() {
        return this.getBody().find('td').first();
    },
    getBodyInstance: function() {
        return this.getBody().dataget('instance');
    },
    getRect: function() {
        return this.getFrameRect();
    },
    getFrameRect: function() {
        var offset = this.$editor.offset();
        var width = this.$editor.width();
        var height = this.$editor.height();
        var top = Math.round(offset.top);
        var left = Math.round(offset.left);

        return {
            top: top,
            left: left,
            bottom: top + height,
            right: left + width
        };
    },
    getText: function() {
        var template = this.$template.html();

        template = this.app.utils.wrap(template, function($w) {
            $w.find('a, re-link, re-button').each(function($node) {
                var href = $node.attr('href');
                var html = $node.html().trim();
                html = html + ' (' + href + ')';

                $node.html(html);
            });

            $w.find('re-heading').each(function($node) {
                var text = '*** ' + $node.text().trim().toUpperCase();
                $node.text(text);
            });

            $w.find('re-template, re-menu, re-social, re-head, re-preheader, re-options').remove();

        });

        template = template.replace(/<re-footer/gi, "----<re-footer");
        template = template.replace(/<\/(re-text|re-link|re-button|re-heading)>/gi, "</$1>\n");
        template = template.replace(/<br\s?\/?>/gi, '\n');

        var div = this.dom('<div>').html(template).get();
        template = div.textContent || div.innerText || '';

        var str = '';
        var arr = template.split("\n");
        for (var i = 0; i < arr.length; i++) {
            str += arr[i].trim() + "\n";
        }

        template = str.trim();
        template = template.replace(/[\n]+/g, "\n\n");

        return template;
    },
    getHtml: function(tidy) {
        return this.app.parser.unparse(tidy);
    },
    getTemplateElement: function() {
        return this.$template;
    },
    getTemplateSourceElement: function() {
        return this.$templateSource;
    },
    getTemplate: function(tidy) {
        return this._getTemplate(this.$template.html(), tidy);
    },
    getTemplateSource: function(tidy) {
        var code;
        if (this.app.editor.isSourceMode()) {
            code = this.app.source.$source.val();
        }
        else {
            code = this._getTemplate(this.$templateSource.html(), tidy);
        }

        return code;
    },
    unset: function() {
        if (this.$elements.length > 0) {
            this.$elements.removeClass(this.prefix + '-element-active ' + this.prefix + '-element-hover');
            this.$template.find('.' + this.prefix + '-element-active').removeClass(this.prefix + '-element-active');
        }
    },
    unsetHover: function() {
        if (this.$elements.length > 0) {
            this.$elements.removeClass(this.prefix + '-element-hover');
        }
    },
    unsetActive: function() {
        if (this.$elements.length > 0) {
            this.$elements.removeClass(this.prefix + '-element-active');
            this.$template.find('.' + this.prefix + '-element-active').removeClass(this.prefix + '-element-active');
        }
    },
    adjustHeight: function(value) {
        setTimeout(function() {
            var $target = this.getBody();
            var height = $target.height() + (value || 0);

            height = (height < 140) ? 140 : height;

            this.$editor.height(height);

        }.bind(this), 50);
    },
    render: function($nodes, $source) {
        this.app.parser.render($nodes, $source);
        this._reload();
    },
    buildEmptyLayers: function() {
        if (this.opts.editor.viewOnly) return;

        var types = ['main', 'header', 'footer'];
        var $el = this.getBody();
        var $layers = this.app.element.getChildren($el, types);

        $layers.each(function($node) {
            var instance = $node.dataget('instance');
            if (!instance.getTarget().hasClass(this.prefix + '-empty-layer')) {
                var $elms = instance.getElements();
                if ($elms.length === 0) {
                    var $target = instance.getTarget();
                    $target.addClass(this.prefix + '-empty-layer');

                    var obj = { command: 'component.openAdd', classname: this.prefix + '-plus-button' };
                    this.app.create('button', 'addempty', obj, $target);
                }
            }
        }.bind(this));

    },
    isPopupSelection: function() {
        return true;
    },
    isImageChange: function() {
        var o = this.opts.image;
        if (!o || (!o.upload && !o.url)) {
            return false;
        }

        return true;
    },
    isSourceMode: function() {
        return (this.app.container.get('editor').css('display') === 'none');
    },
    isMobileMode: function() {
        return this.mobileMode;
    },
    toggleView: function() {
        if (this.mobileMode) {
            this.$editor.css('width', '');
            this.app.event.run();
            this.app.path.enable();
            this.app.toolbar.enableButtons();
            this.app.toolbar.unsetToggled('mobile');
            this.mobileMode = false;
        }
        else {
            this.$editor.css('width', this.opts.editor.mobile + 'px');
            this.app.event.pause();
            this.app.component.unset();
            this.app.path.disable();
            this.app.toolbar.disableButtons(['mobile']);
            this.app.toolbar.setToggled('mobile');
            this.app.popup.close();
            this.app.control.close();
            this.mobileMode = true;
        }

        this.adjustHeight();
    },
    observe: function(obj, name) {
        if (name === 'background') {
            obj.background = this.getBodyInstance().getData('background-color');
        }

        return obj;
    },
    popup: function(params, button, name) {
        this.popups.open(button, name);
    },
    getData: function() {
        var instance = this.getBodyInstance();
        var data = instance.getData();

        return data;
    },
    setData: function(stack) {
        var button = this.app.popup.getButton();
        var data = stack.getData();
        var instance = this.getBodyInstance();

        // button
        button.setColor(stack, data);

        // instance
        instance.setData(data);
        this.adjustHeight();
    },

    // private
    _build: function() {
        this.$editor = this.dom('<iframe>');
        this.$editor.addClass(this.prefix + '-editor').css('visibility', 'hidden');

        this.app.container.get('editor').append(this.$editor);
    },
    _buildState: function() {
        this.app.state.build();
    },
    _buildObserver: function() {
        this.app.observer.build();
    },
    _buildBodyInstance: function() {
        var $source = this.$template.find('re-body');
        var $body = this.getBody();

        this.app.create('tag.body', $source, $body, true);
    },
    _buildTemplate: function() {
        this.ajax.get({
            url: this.opts.editor.template,
            data: { d: new Date().getTime() },
            success: this._buildContent.bind(this)
        });
    },
    _buildTemplateSource: function(template) {
        template = template.trim();

        // set initial template
        this.$templateSource = this.dom('<div>');
        this.$templateSource.html(template);
    },
    _buildContent: function(template) {
        // event
        var event = this.app.broadcast('editor.before.render', { template: template });
        template = event.get('template');

        this._buildTemplateSource(template);

        // parse
        this.app.parser.parse();
    },
    _buildElements: function() {
        var $el = this.getBody();
        this.$elements = this.app.element.getChildren($el, this.opts._elements);
    },
    _buildBlocksOpts: function() {
        for (var key in this.app._store) {
            if (this.app._store[key].type === 'block') {
                var obj = this.app._store[key].proto.prototype;

                // add to opts
                if (typeof this.opts._blocks[obj.section] === 'undefined') {
                    this.opts._blocks[obj.section] = {};
                }

                var title = (obj.title) ? obj.title : this.lang.get('blocks.' + obj.type);
                var priority = obj.priority || false;
                if (this.opts.blocks.hidden && this.opts.blocks.hidden === 'all' && priority) {
                    continue;
                }

                var data = { type: obj.type, icon: obj.icon, title: title };

                if (priority) {
                    this.opts._blocks[obj.section][priority] = data;
                }
                else {
                    var getMaxKeyFromObj = function(obj) {
                        var keys = Object.keys(obj);
                        return (keys.length > 0) ? keys.reduce(function(a, b){ return obj[a] > obj[b] ? a : b }) : 0;
                    };
                    var maxKey = parseInt(getMaxKeyFromObj(this.opts._blocks[obj.section]));
                    this.opts._blocks[obj.section][maxKey+1] = data;
                }
            }
        }
    },
    _buildOptions: function() {
        var $e = this.$editor;
        var o = this.opts.editor;

        if (this.opts.direction === 'rtl') {
            this.opts.editor.align = 'right';
        }

        //$e.attr('dir', o.direction);
        $e.attr('scrolling', 'no');

        if (o.minHeight) $e.css('min-height', o.minHeight);
        if (o.maxHeight) {
            $e.css('max-height', o.maxHeight);
            $e.attr('scrolling', 'yes');
        }
        if (o.notranslate) $e.addClass('notranslate');
        if (!o.spellcheck) $e.attr('spellcheck', false);
    },
    _buildUICss: function() {
        // frame css
        if (this.opts.editor.path) {
            this._buildCssLink(this.opts.editor.path + this.cssfile);
        }

        // plugins css
        for (var i = 0; i < this.opts.pluginsCss.length; i++) {
            this._buildCssLink(this.opts.pluginsCss[i]);
        }

    },
    _buildCssLink: function(href) {
        var $css = this.dom('<link>').attr({ 'class': this.prefix + '-css', 'type': 'text/css', 'rel': 'stylesheet', 'href': href });
        this.getHead().append($css);
    },
    _buildVisibility: function() {
        this.$editor.css('visibility', 'visible');
    },
    _buildImage: function($img) {
        if (this.opts.editor.images) {
            var img = $img.get();
            var arr = img.src.split('/');
            var last = arr[arr.length-1];
            img.src = this.opts.editor.images + last;
        }

        $img.one('load', this._loadImage.bind(this));
    },

    _loaded: function() {
        this.adjustHeight();

        // build
        this._buildVisibility();
        this._buildUICss();
        this._buildBodyInstance();

        if (this.stateLoad === false) {
            this._buildState();
        }

        this._buildObserver();
        this.rebuild();

        // event
        if (this.stateLoad === false) {
            this.app.broadcast('editor.load');
        }
    },
    _load: function() {
        try {
            this._loadImages();
            this._loaded();
        }
        catch(e) {
            Revolvapp.error(e);
        }
    },
    _reload: function() {
        try {
            this._loadImages();
            this.adjustHeight();
            this.rebuild();
        }
        catch(e) {
            Revolvapp.error(e);
        }
    },
    _loadImages: function() {
        var $doc = this.getDoc();
        var $images = $doc.find('img');
        this.imageslen = $images.length;

        $images.each(this._buildImage.bind(this));
        var timerImg = setInterval(function() {
            if (this.imageslen === 0) {
                this.adjustHeight();
                clearInterval(timerImg);
                return;
            }
        }.bind(this), 50);
    },
    _loadImage: function() {
        this.imageslen--;
    },
    _getTemplate: function(template, tidy) {
        template = this.app.content.removeTemplateUtils(template);
        template = (tidy === true) ? this.app.tidy.parse(template, 'source') : template;

        return template
    }
});
Revolvapp.add('class', 'editor.popups', {
    init: function() {},
    open: function(button, name) {
        if (name === 'background') this.background(button);
        else if (name === 'tune') this.settings(button);
    },
    settings: function(button) {
        var instance = this.app.editor.getBodyInstance();

        // stack
        this.app.popup.create('settings', {
            width: '300px',
            title: instance.getTitle(),
            getter: 'editor.getData',
            setter: 'editor.setData',
            form: instance.forms.settings
        });

        this.app.popup.open({ button: button });
    },
    background: function(button) {
        var instance = this.app.editor.getBodyInstance();

        // stacks
        this.app.popup.create('background', {
            title: '## popup.background ##',
            width: '320px',
            getter: 'editor.getData',
            setter: 'editor.setData',
            form: instance.forms.background
        });

        if (this.app.editor.isImageChange()) {
            this.app.popup.add('background-image', {
                collapse: false,
                width: '400px',
                title: '## popup.background-image ##',
                instance: instance,
                getter: 'editor.getData',
                setter: 'editor.setData',
                form: instance.forms.backgroundimage
            });
        }

        this.app.popup.open({ button: button });
    },
});
Revolvapp.add('module', 'event', {
    init: function() {
        this.eventname = this.prefix + '-editor-events';
        this.eventpreventname = this.prefix + '-editor-prevent-events';
        this.dragoverEvent = false;
        this.isPopupMouse = false;

        // events
        this.frameEvents = ['mousedown', 'mouseover', 'keydown', 'keyup', 'paste', 'drop', 'dragstart', 'dragover', 'dragleave'];
        this.docEvents = ['click', 'mousedown', 'keydown'];
    },
    stop: function() {
        if (this.$frameBody) {
            this.$frameBody.off('.' + this.eventname);
            this.app.$doc.off('.' + this.eventname);
        }
    },
    pause: function() {
        if (this.$frameBody) {
            this.$frameBody.off('.' + this.eventname);
            this.app.$doc.off('.' + this.eventname);
        }
    },
    run: function() {
        if (this.$frameBody) {
            this._buildEvents();
        }
    },
    build: function() {
        this.$frameBody = this.app.editor.getBody();
        this.stop();
        this.buildPreventLinks();
        this._buildEvents();
    },
    buildPreventLinks: function() {
        this.app.editor.getBody().on('click.' + this.eventpreventname + ' dblclick.' + this.eventpreventname, this.preventLinks.bind(this));
    },
    preventLinks: function(e) {
        // prevent link clicks
        if (this._isLinkClick(e)) {
            e.preventDefault();
        }
    },
    onmouseover: function(e) {
        var $target = this.dom(e.target);
        var $element = this._getElementFromTarget($target);

        // noneditable
        if (this._isNoneditable($element)) {
            return;
        }

        // unset hover
        this.app.editor.unsetHover();

        // element hover
        if ($element.length !== 0 && !$element.hasClass(this.prefix + '-element-active')) {
            $element.addClass(this.prefix + '-element-hover');
        }

        this.app.broadcast('event.mouseover', { e: e });
    },
    onmousedown: function(e) {
        // target
        var $target = this.dom(e.target);
        var $element = this._getElementFromTarget($target);

        // element
        if ($element.length !== 0 && !this._isNoneditable($element)) {
            this.app.component.set($element);
        }
        else if (this.app.popup.isOpen()) {
            this.app.popup.close();
        }
        else {
            this.app.component.unset();
        }

        this.app.state.build(true);
        this.app.broadcast('event.click', { e: e });
    },
    onkeydown: function(e) {

        // key
        var key = e.which;
        var k = this.app.keycodes;

        // listen undo & redo
        if (this.app.state.listen(e)) {
            return;
        }

        // esc
        if (key === k.ESC) {
            if (this.app.popup.isOpen()) {
                this.app.popup.close();
            }
            else if (this.app.component.is()) {
                this.app.component.unset();
            }
        }

        // broadcast
        var eventObj = this._buildEventKeysObj(e);
        var event = this.app.broadcast('event.keydown', eventObj);
        if (event.isStopped()) return e.preventDefault();

        // handle shortcut
        if (this.app.shortcut.handle(e)) {
            return;
        }

        // release keydown
        this.app.input.handle(event);
    },
    onkeyup: function(e) {
        var instance = this.app.component.get();
        var block = this.app.selection.getCurrent();

        // typing
        var $block = this.dom(block).closest('[data-' + this.prefix + '-type]');
        if ($block.length !== 0) {
            instance = $block.dataget('instance');
            if (instance && (instance.isEditable() || instance.isType('list-item')) && !this.app.component.is($block)) {
                this.app.state.build();
                $block = (instance.isType('list-item')) ? $block.closest('[data-' + this.prefix + '-type=list]') : $block;
                this.app.component.set($block, false, true, false);
            }
        }

        // update control position
        instance = this.app.component.get();
        if (this.app.component.is() && instance.isEditable()) {
            this.app.control.updatePosition();
            this.app.component.sync();
        }

        this.app.broadcast('event.keyup', { e: e });
    },
    onpaste: function(e) {
        // broadcast
        var event = this.app.broadcast('event.paste', { e: e });
        if (event.isStopped()) return e.preventDefault();

        // paste
        this.app.component.paste(e);
    },
    ondrop: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var dt = e.dataTransfer;
        if (dt.files !== null && dt.files.length > 0) {
            this.app.component.drop(e, dt);
        }

        // broadcast
        this.app.broadcast('event.drop', { e: e });
    },
    ondragstart: function(e) {
        // broadcast
        this.app.broadcast('event.dragstart', { e: e });
    },
    ondragover: function(e) {
        e.preventDefault();
        this.dragoverEvent = true;

        // broadcast
        this.app.broadcast('event.dragover', { e: e });
    },
    ondragleave: function(e) {
        e.preventDefault();
        this.dragoverEvent = false;

        // broadcast
        this.app.broadcast('event.dragleave', { e: e });
    },
    ondocclick: function(e) {
        if (!this.isPopupMouse && this.app.popup.isOpen()) {
            this.app.popup.close(e);
        }

        var isPopup = (this.dom(e.target).closest('.' + this.prefix + '-popup').length !== 0);
        if (!isPopup) {
            this.app.component.unset();
        }

        this.isPopupMouse = false;
    },
    ondocmousedown: function(e) {
        var $target = this.dom(e.target);
        this.isPopupMouse = ($target.closest('.' + this.prefix + '-popup').length !== 0);
    },
    ondockeydown: function(e) {
        // key
        var key = e.which;
        var k = this.app.keycodes;

        // esc
        if (key === k.ESC) {
            if (this.app.popup.isOpen()) {
                this.app.popup.close();
            }
        }
    },

    // private
    _isLinkClick: function(e) {
        return (this.dom(e.target).closest('a').length !== 0);
    },
    _isNoneditable: function($element) {
        return ($element.closest('[noneditable]').length !== 0);
    },
    _getElementFromTarget: function($target) {
        return this.app.element.getClosest($target, this.opts._elements);
    },
    _buildEvents: function() {
        for (var i = 0; i < this.frameEvents.length; i++) {
            this.$frameBody.on(this.frameEvents[i] + '.' + this.eventname, this['on' + this.frameEvents[i]].bind(this));
        }

        for (var z = 0; z < this.docEvents.length; z++) {
            this.app.$doc.on(this.docEvents[z] + '.' + this.eventname, this['ondoc' + this.docEvents[z]].bind(this));
        }
    },
    _buildEventKeysObj: function(e) {
        var key = e.which;
        var arrowKeys = [this.app.keycodes.UP, this.app.keycodes.DOWN, this.app.keycodes.LEFT, this.app.keycodes.RIGHT];
        var isAlphaKeys = ((!e.ctrlKey && !e.metaKey) && ((key >= 48 && key <= 57) || (key >= 65 && key <= 90)));
        var k = this.app.keycodes;

        return {
            'e': e,
            'key': key,
            'ctrl': (e.ctrlKey || e.metaKey),
            'shift': (e.shiftKey),
            'alt': (e.altKey),
            'select': ((e.ctrlKey || e.metaKey) && !e.altKey && key === 65),
            'enter': (key === k.ENTER),
            'space': (key === k.SPACE),
            'esc': (key === k.ESC),
            'tab': (key === k.TAB && !e.shiftKey && !e.altKey && !e.ctrlKey && !e.metaKey),
            'delete': (key === k.DELETE),
            'backspace': (key === k.BACKSPACE),
            'alpha': isAlphaKeys,
            'arrow': (arrowKeys.indexOf(key) !== -1),
            'left': (key === k.LEFT),
            'right': (key === k.RIGHT),
            'up': (key === k.UP),
            'down': (key === k.DOWN),
            'left-right': (key === k.LEFT || key === k.RIGHT),
            'up-left': (key === k.UP || key === k.LEFT),
            'down-right': (key === k.DOWN || key === k.RIGHT)
        };
    }
});
Revolvapp.add('module', 'link', {
    popups: {
        add: {
            width: '400px',
            title: '## popup.insert-link ##',
            form: {
                'text': {
                    type: 'input',
                    label: '## form.text ##'
                },
                'href': {
                    type: 'input',
                    label: '## form.url ##'
                }
            },
            footer: {
                insert: { title: '## buttons.insert ##', command: 'link.insert', type: 'primary' },
                cancel: { title: '## buttons.cancel ##', close: true }
            }
        },
        edit: {
            width: '400px',
            title: '## popup.edit-link ##',
            form: {
                'text': {
                    type: 'input',
                    label: '## form.text ##'
                },
                'href': {
                    type: 'input',
                    label: '## form.url ##'
                }
            },
            footer: {
                save: { title: '## buttons.save ##', command: 'link.save', type: 'primary' },
                unlink: { title: '## buttons.unlink ##', command: 'link.unlink', type: 'danger' },
                cancel: { title: '## buttons.cancel ##', close: true }
            }
        }
    },
    init: function() {},
    popup: function(params, button) {
        var data = this._getData();
        var $link = this._getLink();
        var type = ($link) ? 'edit' : 'add';

        var stack = this.app.popup.create('link', this.popups[type]);
        stack.setData(data);

        this.app.popup.open({ button: button, focus: 'href' });
    },
    insert: function(stack) {
        var data = stack.getData();
        this.app.popup.close();

        if (data.href.search(/^javascript:/i) !== -1) {
            data.href = '';
        }

        if (data.href !== '') {
            var instance = this.app.component.get();
            var linkCss = instance.getLinkData();
            var nodes = this.app.inline.format({ tag: 'a' });
            var $link = this.dom(nodes[0]);
            $link.css(linkCss);

            data.text = (data.text === '') ? data.href : data.text;

            $link.text(data.text);

            var value = this.app.content.replaceToHttps('href', data.href);
            $link.attr('href', value);

            instance.sync();

            this.app.caret.set($link, 'after');
            this.app.broadcast('link.add', { url: data.href, text: data.text });
        }
    },
    save: function(stack) {
        var data = stack.getData();
        this.app.popup.close();

        if (data.href.search(/^javascript:/i) !== -1) {
            data.href = '';
        }

        if (data.href !== '') {
            var instance = this.app.component.get();
            var $link = this._getLink();

            data.text = (data.text === '') ? data.href : data.text;

            $link.text(data.text);

            var value = this.app.content.replaceToHttps('href', data.href);
            $link.attr('href', value);

            instance.sync();

            this.app.broadcast('link.change', { url: data.href, text: data.text });
        }
    },
    unlink: function() {
        this.app.popup.close();

        var links = this.app.selection.getNodes({ type: 'inline', tags: ['a'] });
        if (links.length !== 0) {
            var instance = this.app.component.get();
            for (var i = 0; i < links.length; i++) {
                var $link = this.dom(links[i]);

                this.app.broadcast('link.remove', { url: $link.attr('href'), text: $link.text() });
                $link.unwrap();
                instance.sync();
            }
        }
    },

    // private
    _getData: function() {
        var $link = this._getLink();
        var data = {
            'text': ($link) ? $link.text() : this.app.selection.getText(),
            'href': ($link) ? $link.attr('href') : ''
        };

        return data;
    },
    _getLink: function() {
        var links = this.app.selection.getNodes({ tags: ['a'] });

        return (links.length !== 0) ? this.dom(links[0]) : false;
    }
});
Revolvapp.add('module', 'state', {
    init: function() {
        this.prevState = '';
        this.undoStorage = [];
        this.redoStorage = [];
    },
    stop: function() {
        this.clear();
    },
    is: function() {
        return (this.app.content.removeTemplateUtils(this.app.editor.$template.html()) === this.app.state.prevState);
    },
    build: function(click) {
        var el = this.app.editor.$template.get();
        var lastState = this._getLastUndo();
        this.prevState = this.app.content.removeTemplateUtils(this.app.editor.$template.html());
        var data = {
            initial: true,
            editable: false,
            html: el.innerHTML,
            offset: false
        };

        if (!lastState) {
            this._setUndo(data);
        }
        else if (click && lastState.initial) {
            data.initial = false;

            var instance = this.app.component.get();
            if (instance) {
                var $el = instance.getElement();
                if ($el && instance.isEditable()) {
                    data.offset = this.app.offset.get($el);
                }
            }

            this._replaceUndo(0, data);
        }
    },
    clear: function() {
        this.prevState = '';
        this.undoStorage = [];
        this.redoStorage = [];
    },
    listen: function(e) {
        // undo
        if (this._isUndo(e)) {
            e.preventDefault();
            this.undo();
            return true;
        }
        // redo
        else if (this._isRedo(e)) {
            e.preventDefault();
            this.redo();
            return true;
        }
    },
    add: function(el, editable) {

        var instance = this.app.component.get();
        var offset = false;
        if (instance) {
            var $el = instance.getElement();
            offset = (editable) ? this.app.offset.get($el) : offset;
        }
        var html = el.innerHTML;
        var lastState = this._getLastUndo();

        this.prevState = this.app.content.removeTemplateUtils(this.app.editor.$template.html());

        if (lastState && html !== lastState.html) {
            var data = {
                initial: false,
                editable: editable,
                html: html,
                offset: offset
            };

            this._setUndo(data);
        }
    },
    undo: function() {
        if (!this._hasUndo()) return;

        var data = this._getUndo();
        if (data) {
            this.app.editor.setState(data.html, data.offset);

            // event
            this.app.broadcast('state.undo');
        }
    },
    redo: function() {
        if (!this._hasRedo()) return;

        var data = this._getRedo();
        if (data) {
            this._setUndo(data);
            this.app.editor.setState(data.html, data.offset);

            // event
            this.app.broadcast('state.redo');
        }
    },

    // private
    _hasUndo: function() {
        return (this.undoStorage.length !== 0);
    },
    _hasRedo: function() {
        return (this.redoStorage.length !== 0);
    },
    _isUndo: function(e) {
        var key = e.which;
        var ctrl = e.ctrlKey || e.metaKey;

        return (ctrl && key === 90 && !e.shiftKey && !e.altKey);
    },
    _isRedo: function(e) {
        var key = e.which;
        var ctrl = e.ctrlKey || e.metaKey;

        return (ctrl && (key === 90 && e.shiftKey || key === 89 && !e.shiftKey) && !e.altKey);
    },
    _getRedo: function() {
        return (this.redoStorage.length === 0) ? false : this.redoStorage.pop();
    },
    _getUndo: function() {
        var data;
        if (this.undoStorage.length === 0) {
            data = false;
        }
        else if (this.undoStorage.length === 1) {
            data = this.undoStorage[0];
            this._setRedo(data);
        }
        else {
            var redo = this.undoStorage.pop();
            this._setRedo(redo);
            data = this.undoStorage.pop();
            this._setUndo(data);
        }

        return data;
    },
    _getLastUndo: function() {
        return (this.undoStorage.length === 0) ? false : this.undoStorage[this.undoStorage.length-1];
    },
    _setRedo: function(data) {
        this.redoStorage.push(data);
        this.redoStorage = this.redoStorage.slice(0, this.opts.buffer.limit);
    },
    _setUndo: function(data) {
        this.undoStorage.push(data);
        this._removeOverStorage();
    },
    _replaceUndo: function(index, data) {
        this.undoStorage[index] = data;
    },
    _removeOverStorage: function() {
        if (this.undoStorage.length > this.opts.buffer.limit) {
            this.undoStorage = this.undoStorage.slice(0, (this.undoStorage.length - this.opts.buffer.limit));
        }
    }
});
Revolvapp.add('module', 'tidy', {
    init: function() {},
    parse: function(code, type) {

        code = code.replace(/\n\s+/g, '\n');
        code = code.replace(/\t/g, '    ');
        code = code.replace(/<!--\s+</g, '<!-- <');
        code = code.replace(/\n/g, '');

        // clean setup
        var ownLine = ['re-style', 'style', 'meta', 'link', 'li'];
        var contOwnLine = ['li'];
        var newLevel = ['re-container', 're-title', 're-social', 're-menu', 're-font', 're-link', 're-list', 're-list-item',
                         're-spacer', 're-text', 're-heading', 're-body', 're-head', 're-header', 're-footer', 're-divider',
                        're-menu-item', 're-main', 're-block', 're-grid', 're-column', 're-preheader', 're-button'];

        if (type === 'html') {
            newLevel = ['p', 'ul', 'ol', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'title', 'head', 'body', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th'];
        }

        this.lineBefore = new RegExp('^<(/?' + ownLine.join('|/?' ) + '|' + contOwnLine.join('|') + ')[ >]');
        this.lineAfter = new RegExp('^<(br|/?' + ownLine.join('|/?' ) + '|/' + contOwnLine.join('|/') + ')[ >]');
        this.newLevel = new RegExp('^</?(' + newLevel.join('|' ) + ')[ >]');

        var i = 0,
        codeLength = code.length,
        point = 0,
        start = null,
        end = null,
        tag = '',
        out = '',
        cont = '';

        this.cleanlevel = 0;

        for (; i < codeLength; i++) {
            point = i;

            // if no more tags, copy and exit
            if (-1 == code.substr(i).indexOf( '<' )) {
                out += code.substr(i);

                return this.finish(out, type);
            }

            // copy verbatim until a tag
            while (point < codeLength && code.charAt(point) != '<') {
                point++;
            }

            if (i != point) {
                cont = code.substr(i, point - i);
                if (!cont.match(/^\s{2,}$/g)) {
                    if ('\n' == out.charAt(out.length - 1)) out += this.getTabs();
                    else if ('\n' == cont.charAt(0)) {
                        out += '\n' + this.getTabs();
                        cont = cont.replace(/^\s+/, '');
                    }

                    out += cont;
                }

                if (cont.match(/\n/)) out += '\n' + this.getTabs();
            }

            start = point;

            // find the end of the tag
            while (point < codeLength && '>' != code.charAt(point)) {
                point++;
            }

            tag = code.substr(start, point - start);
            i = point;

            var t;

            if ('!--' == tag.substr(1, 3)) {
                if (!tag.match(/--$/)) {
                    while ('-->' != code.substr(point, 3)) {
                        point++;
                    }
                    point += 2;
                    tag = code.substr(start, point - start);
                    i = point;
                }

                if ('\n' != out.charAt(out.length - 1)) out += '\n';

                out += this.getTabs();
                out += tag + '>\n';
            }
            else if ('!' == tag[1]) {
                out = this.placeTag(tag + '>', out);
            }
            else if ('?' == tag[1]) {
                out += tag + '>\n';
            }
            else if (t === tag.match(/^<(script|style|pre)/i)) {
                t[1] = t[1].toLowerCase();
                tag = this.cleanTag(tag);
                out = this.placeTag(tag, out);
                end = String(code.substr(i + 1)).toLowerCase().indexOf('</' + t[1]);

                if (end) {
                    cont = code.substr(i + 1, end);
                    i += end;
                    out += cont;
                }
            }
            else {
                tag = this.cleanTag(tag);
                out = this.placeTag(tag, out);
            }
        }

        return this.finish(out, type);
    },
    getTabs: function() {
        var s = '';
        for ( var j = 0; j < this.cleanlevel; j++ ) {
            s += '    ';
        }

        return s;
    },
    finish: function(code, type) {
        code = code.replace(/\n\s*\n/g, '\n');
        code = code.replace(/^[\s\n]*/, '');
        code = code.replace(/[\s\n]*$/, '');
        code = code.replace(/<script(.*?)>\n<\/script>/gi, '<script$1></script>');

        if (this.opts.editor.delimiters) {
            var stored = this.app.parser._store(code);
            code = stored.html;

            var delims = this.opts.editor.delimiters;
            for (var key in delims) {
                code = code.replace(new RegExp(delims[key][1] + '\\n', 'g'), delims[key][1]);
                code = code.replace(new RegExp(delims[key][1], 'g'), delims[key][1] + '\n');
            }

            // restore tags
            code = this.app.parser._restoreReplaced(stored.data, code);
            code = this.app.parser._restoreReplaced(stored.data, code);
        }

        this.cleanlevel = 0;

        if (type !== 'html') {
            var closeTags = ['re-font', 're-mobile-spacer', 're-column-spacer', 're-image', 're-divider', 're-spacer'];
            var re = new RegExp('>\\n\\s+</(' + closeTags.join('|') + ')>', 'g');

            code = code.replace(re, '></$1>');
        }

        return code;
    },
    cleanTag: function (tag) {
        var tagout = '';
        tag = tag.replace(/\n/g, ' ');
        tag = tag.replace(/\s{2,}/g, ' ');
        tag = tag.replace(/^\s+|\s+$/g, ' ');

        var suffix = '';
        if (tag.match(/\/$/)) {
            suffix = '/';
            tag = tag.replace(/\/+$/, '');
        }

        var m;
        do {
            m = /\s*([^= ]+)(?:=((['"']).*?\3|[^ ]+))?/.exec(tag);
            if (m != null) {
                if (m[2]) tagout += m[1].toLowerCase() + '=' + m[2];
                else if (m[1]) tagout += m[1].toLowerCase();

                tagout += ' ';
                tag = tag.substr(m[0].length);
            }
        }
        while (m);

        return tagout.replace(/\s*$/, '') + suffix + '>';
    },
    placeTag: function (tag, out) {
        var nl = tag.match(this.newLevel);

        if (tag.match(this.lineBefore) || nl) {
            out = out.replace(/\s*$/, '');
            out += '\n';
        }

        if (nl && '/' == tag.charAt(1)) this.cleanlevel--;
        if ('\n' == out.charAt(out.length - 1)) out += this.getTabs();
        if (nl && '/' != tag.charAt(1)) this.cleanlevel++;

        out += tag;

        if (tag.match(this.lineAfter) || tag.match(this.newLevel)) {
            out = out.replace(/ *$/, '');
            out += '\n';
        }

        return out;
    }
});
Revolvapp.add('module', 'inline', {
    init: function() {},
    removeFormat: function() {

        var instance = this.app.component.get();
        if (!instance || !instance.isEditable()) return;

        this.app.selection.save(instance.getTarget());

        var nodes = this.app.selection.getNodes({ type: 'inline' });
        for (var i = 0; i < nodes.length; i++) {
            this.dom(nodes[i]).unwrap();
        }

        this.app.selection.restore(instance.getTarget());
    },
    format: function(args) {
        // popup
        if (this.app.popup.isOpen()) {
            this.app.popup.close();
        }

        this.params = this._buildParams(args);

        var nodes = [];
        if (this.app.selection.isCollapsed()) {
            nodes = this.formatCollapsed();
        }
        else {
            nodes = this.formatUncollapsed();
        }

        this.app.broadcast('inline.format', { nodes: nodes });

        return nodes;
    },
    formatCollapsed: function() {
        var node;
        var nodes = [];
        var inline = this.app.selection.getInline();
        var $inline = this.dom(inline);
        var hasSameTag = (inline && inline.tagName.toLowerCase() === this.params.tag);

        // 1) not inline
        if (!inline) {
            node = this._insertInline(nodes, this.params.tag);
        }
        else {
            // 2) inline is empty
            if (this.app.content.isEmptyHtml(inline.innerHTML)) {
                // 2.1) has same tag
                if (hasSameTag) {
                    this.app.caret.set(inline, 'after');
                    $inline.remove();
                }
                // 2.2) has a different tag
                else {
                    var $el = this.app.element.replaceToTag(inline, this.params.tag);
                    this.app.caret.set($el, 'start');
                }
            }
            // 3) inline isn't empty
            else {
                // 3.1) has same tag
                if (hasSameTag) {

                    var extractedContent = this.app.content.extractHtmlFromCaret(inline);
                    var $secondPart = this.dom('<' + this.params.tag + ' />');
                    $secondPart = this.app.element.cloneAttrs(inline, $secondPart);
                    $inline.after($secondPart.append(extractedContent));

                    this.app.caret.set($secondPart, 'before');
                }
                // 3.2) has a different tag
                else {
                    node = this._insertInline(nodes, this.params.tag);
                }
            }
        }

        if (node) {
            nodes = [node];
        }

        return nodes;
    },
    formatUncollapsed: function() {

        var instance = this.app.component.get();
        var inlines = this.app.selection.getNodes({ type: 'inline' });

        // convert del / u
        this._convertTags('u', instance);

        // convert target tags
        this._convertToStrike(inlines, instance);

        // save selection
        this.app.selection.save(instance.getTarget());

        // apply strike
        this.app.editor.getDoc().get().execCommand('strikethrough');


        // revert to inlines
        var nodes = this._revertToInlines(instance);

        // restore selection
        this.app.selection.restore(instance.getTarget());

        // filter if node is not selected
        var finalNodes = [];
        var selected = this.app.selection.getText();
        for (var i = 0; i < nodes.length; i++) {
            if (this._isInSelection(nodes[i], selected)) {
                finalNodes.push(nodes[i]);
            }
        }

        // clear and normalize
        this._clearEmptyStyle();

        // apply attr
        if (typeof this.params.attr !== 'undefined') {
            for (var z = 0; z < finalNodes.length; z++) {
                for (var name in this.params.attr) {
                    finalNodes[z].setAttribute(name, this.params.attr[name]);
                }
            }
        }

        this.app.selection.save(instance.getTarget());
        instance.getTarget().get().normalize();
        this._revertTags('u', instance);
        this.app.selection.restore(instance.getTarget());

        return finalNodes;
    },

    // private
    _clearEmptyStyle: function() {
        var inlines = this.app.selection.getNodes({ type: 'inline' });
        for (var i = 0; i < inlines.length; i++) {
            this._clearEmptyStyleAttr(inlines[i]);

            var childNodes = inlines[i].childNodes;
            if (childNodes) {
                for (var z = 0; z < childNodes.length; z++) {
                    this._clearEmptyStyleAttr(childNodes[z]);
                }
            }
        }
    },
    _clearEmptyStyleAttr: function(node) {
        if (node.nodeType !== 3 && node.getAttribute('style') === '') {
            node.removeAttribute('style');
        }
    },
    _isInSelection: function(node, selected) {
        var text = this.app.utils.removeInvisibleChars(node.textContent);

        return (text.search(new RegExp(this.app.utils.escapeRegExp(selected))) !== -1);
    },
    _buildParams: function(args) {
        var params = true;
        var obj = {};
        var values = ['tag', 'classname', 'attr'];
        for (var i = 0; i < values.length; i++) {
            if (Object.prototype.hasOwnProperty.call(args, values[i])) {
                obj[values[i]] = args[values[i]];
                params = false;
            }
        }

        return (params) ? args.params : obj;
    },
    _insertInline: function(nodes, tag) {
        var inserted = this.app.component.insert(document.createElement(tag), 'start');
        return [inserted];
    },
    _convertTags: function(tag, instance) {
        if (this.params.tag !== tag) {
            instance.getTarget().find(tag).each(function($node) {
                var $el = this.app.element.replaceToTag($node, 'span');
                $el.addClass(this.prefix + '-convertable-' + tag);
            }.bind(this));
        }
    },
    _revertTags: function(tag, instance) {
        instance.getTarget().find('span.' + this.prefix + '-convertable-' + tag).each(function($node) {
            var $el = this.app.element.replaceToTag($node, tag);
            $el.removeClass(this.prefix + '-convertable-' + tag);
            if (this.app.element.removeEmptyAttrs($el, ['class'])) $el.removeAttr('class');

        }.bind(this));
    },
    _convertToStrike: function(inlines, instance) {
        this.app.selection.save(instance.getTarget());
        for (var i = 0; i < inlines.length; i++) {
            var inline = inlines[i];
            var $inline = this.dom(inline);
            var tag = inlines[i].tagName.toLowerCase();

            if (tag === this.params.tag) {
                this._replaceToStrike($inline);
            }
        }
        this.app.selection.restore(instance.getTarget());
    },
    _removeAllAttr: function($elements) {
        $elements.each(function($node) {
            var node = $node.get();
            if (node.attributes.length > 0) {
                var attrs = node.attributes;
                for (var i = attrs.length - 1; i >= 0; i--) {
                    if (attrs[i].name !== 'class') {
                        node.removeAttribute(attrs[i].name);
                    }
                }
            }
        });
    },
    _replaceToStrike: function($el) {
        $el.replaceWith(function() { return this.dom('<strike>').append($el.contents()); }.bind(this));
    },
    _revertToInlines: function(instance) {
        var nodes = [];

        // strike
        instance.getTarget().find('strike').each(function(node) {
            var $node = this.app.element.replaceToTag(node, this.params.tag);
            nodes.push($node.get());

        }.bind(this));


        return nodes;
    }
});
Revolvapp.add('module', 'insertion', {
    init: function() {},
    insertBreakline: function(caret) {
        return this.insertNode(document.createElement('br'), (caret) ? caret : 'after');
    },
    insertChar: function(charhtml, caret) {
        return this.insertNode(charhtml, (caret) ? caret : 'after');
    },
    insertHtml: function(html, caret) {
        var node = this.insertNode(html, (caret) ? caret : 'after');

        // broadcast
        this.app.broadcast('editor.change');

        return node;
    },
    insertFromPaste: function(html, caret) {
        return this._insertFragment({ html: html }, caret);
    },
    insertNode: function(node, caret) {
        if (typeof node === 'string' && !/^\s*<(\w+|!)[^>]*>/.test(node)) {
            node = document.createTextNode(node);
        }

        return this._insertFragment({ node: this.dom(node).get() }, caret);
    },

    // private
    _insertFragment: function(obj, caret) {
        if (obj.html || obj.fragment) {
            var fragment = this.app.fragment.build(obj.html || obj.fragment);
            this.app.fragment.insert(fragment);
        }
        else {
            this.app.fragment.insert(obj.node);
        }

        if (caret) {
            var target = (obj.node) ? obj.node : ((caret === 'start') ? fragment.first : fragment.last);
            this.app.caret.set(target, caret);
        }

        if (obj.node) {
            return this.dom(obj.node);
        }
        else {
            return this.dom(fragment.nodes);
        }
    }
});
Revolvapp.add('module', 'selection', {
    init: function() {
        this.savedSelection = false;
    },
    // get
    get: function() {
        var selection = this._getSelection();
        var range = this._getRange(selection);
        var current = this._getCurrent(selection);

        return {
            selection: selection,
            range: range,
            collapsed: this._getCollapsed(selection, range),
            current: current,
            parent: this._getParent(current)
        };
    },
    getNodes: function(data) {
        var selection = this._getSelection();
        var range = this._getRange(selection);
        var nodes = (selection && range) ? this._getRangeNodes(range) : [];

        // filter
        var finalNodes = [];
        var pushNode, isTagName;
        for (var i = 0; i < nodes.length; i++) {

            pushNode = true;

            if (data) {
                // by type
                if (data.type) {
                    if (data.type === 'inline' && !this.app.element.is(nodes[i], 'inline')) {
                        pushNode = false;
                    }
                }
                // by tag
                if (data.tags) {
                    isTagName = (typeof nodes[i].tagName !== 'undefined');
                    if (!isTagName) {
                        pushNode = false;
                    }

                    if (isTagName && data.tags.indexOf(nodes[i].tagName.toLowerCase()) === -1) {
                        pushNode = false;
                    }
                }
            }

            if (pushNode) {
                finalNodes.push(nodes[i]);
            }
        }

        return finalNodes;
    },
    getCurrent: function() {
        var sel = this._getSelection();
        return this._getCurrent(sel);
    },
    getParent: function() {
        var current = this.getCurrent();
        return this._getParent(current);
    },
    getElement: function(el) {
        return this._getElement(el, 'element');
    },
    getInline: function(el) {
        return this._getElement(el, 'inline');
    },
    getBlock: function(el) {
        return this._getElement(el, 'block');
    },
    getRange: function() {
        var selection = this._getSelection();
        return this._getRange(selection);
    },
    getText: function(type, num) {
        var sel = this.get();
        var text = false;

        if (!sel.selection) return false;
        if (type && sel.range) {
            num = (typeof num === 'undefined') ? 1 : num;

            var el = this.app.editor.$editor.get();
            var clonedRange = sel.range.cloneRange();

            if (type === 'before') {
                clonedRange.collapse(true);
                clonedRange.setStart(el, 0);

                text = clonedRange.toString().slice(-num);
            }
            else if (type === 'after') {
                clonedRange.selectNodeContents(el);
                clonedRange.setStart(sel.range.endContainer, sel.range.endOffset);

                text = clonedRange.toString().slice(0, num);
            }
        }
        else {
            text = (sel.selection) ? sel.selection.toString() : '';
        }

        return text;
    },
    getHtml: function() {
        var html = '';
        var sel = this.get();

        if (sel.selection) {
            var clonedRange = sel.range.cloneContents();
            var div = document.createElement('div');
            div.appendChild(clonedRange);
            html = div.innerHTML;
            html = html.replace(/<p><\/p>$/i, '');
        }

        return html;
    },

    // set
    set: function(sel) {
        if (sel.selection) {
            sel.selection.removeAllRanges();
            sel.selection.addRange(sel.range);
        }
    },
    setRange: function(range) {
        this.set({ selection: this.app.editor.getWinNode().getSelection(), range: range });
    },

    // is
    is: function(el) {
        if (typeof el !== 'undefined') {
            var node = this.dom(el).get();
            var nodes = this.getNodes();

            for (var i = 0; i < nodes.length; i++) {
                if (nodes[i] === node) return true;
            }
        }
        else {
            return this.get().selection;
        }

        return false;
    },
    isCollapsed: function() {
        var sel = this.get();
        var range = this.getRange();

        return this._getCollapsed(sel, range);

    },
    isAll: function(el) {
        var node = this.dom(el).get();
        var selection = this.app.editor.getWinNode().getSelection();
        var range = this._getRange(selection);

        if (selection.isCollapsed) return false;

        if (this.is(node)) {
            return ((typeof node.textContent !== 'undefined') && (node.textContent.trim().length === range.toString().trim().length))
        }
        else {
            return false;
        }
    },

    // collapse
    collapse: function(type) {
        type = type || 'start';

        var sel = this.get();
        if (sel.selection && !sel.collapsed) {
            if (type === 'start') sel.selection.collapseToStart();
            else sel.selection.collapseToEnd();
        }
    },

    // remove
    removeAllRanges: function() {
        this.app.editor.getWinNode().getSelection().removeAllRanges();
    },

    // delete
    deleteContents: function() {
        var range = this.getRange();
        range.deleteContents();
    },


    // save & restore
    save: function(el) {
        this.savedSelection = this.app.offset.get(el);
    },
    restore: function(el) {
        if (!this.savedSelection) return;

        this.app.offset.set(el, this.savedSelection);
        this.savedSelection = false;
    },

    // private
    _getSelection: function() {
        var sel = this.app.editor.getWinNode().getSelection();
        return (sel.rangeCount > 0) ? sel : false;
    },
    _getRange: function(selection) {
        return (selection) ? ((selection.rangeCount > 0) ? selection.getRangeAt(0) : false) : false
    },
    _getCurrent: function(selection) {
        return (selection) ? selection.anchorNode : false;
    },
    _getParent: function(current) {
        var node = (current) ? current.parentNode : false;

        return node = (this._isEditableNode(node)) ? false : node;
    },
    _getElement: function(el, type) {
        var sel = this._getSelection();
        if (sel) {
            var node = el || this._getCurrent(sel);
            node = this.dom(node).get();
            while (node) {
                if (this.app.element.is(node, type) && !this._isEditableNode(node)) {
                    return node;
                }

                node = node.parentNode;
            }
        }

        return false;
    },
    _getCollapsed: function(selection, range) {
        var collapsed = false;
        if (selection && selection.isCollapsed) collapsed = true;
        else if (range && range.toString().length === 0) collapsed = true;

        return collapsed;
    },
    _getNextNode: function(node) {
        if (node.firstChild) return node.firstChild;

        while (node) {
            if (node.nextSibling) return node.nextSibling;
            node = node.parentNode;
        }
    },
    _getRangeNodes: function(range) {
        var start = range.startContainer.childNodes[range.startOffset] || range.startContainer;
        var end = range.endContainer.childNodes[range.endOffset] || range.endContainer;
        var commonAncestor = range.commonAncestorContainer;
        var nodes = [];
        var node;

        for (node = start.parentNode; node; node = node.parentNode) {
            if (this._isEditableNode(node)) break;
            nodes.push(node);
            if (node == commonAncestor) break;
        }

        nodes.reverse();

        for (node = start; node; node = this._getNextNode(node)) {
            if (node.nodeType !== 3 && this.dom(node.parentNode).closest(commonAncestor).length === 0) break;

            nodes.push(node);
            if (node == end) break;
        }

        return nodes;
    },
    _isEditableNode: function(node) {
        return (this.dom(node).hasClass(this.prefix + '-editable'));
    }
});
Revolvapp.add('module', 'autosave', {
    send: function() {
        if (this.opts.autosave.url) {
            this._sending();
        }
    },

    // private
    _sending: function() {
        var data = {
            'html': this.app.editor.getHtml(),
            'template': this.app.editor.getTemplate()
        };

        this.ajax.request(this.opts.autosave.method, {
            url: this.opts.autosave.url,
            data: data,
            before: function(xhr) {
                var event = this.app.broadcast('autosave.before.send', { xhr: xhr, data: data });
                if (event.isStopped()) {
                    return false;
                }
            }.bind(this),
            success: function(response) {
                this._complete(response, data);
            }.bind(this)
        });
    },
    _complete: function(response, data) {
        var callback = (response && response.error) ? 'autosave.error' : 'autosave.send';
        this.app.broadcast(callback, { data: data, response: response });
    }
});
Revolvapp.add('module', 'normalize', {
    init: function() {},
    getter: function(name, value) {
        switch (name) {
            case 'padding':
            case 'margin':
            case 'width':
            case 'href':
            case 'alt':
                value = (value === null) ? '' : value;
                break;
            case 'html':
                value = (value === null) ? '' : value.trim();
                break;
            case 'height':
            case 'font-size':
            case 'border-width':
            case 'border-radius':
                value = (value === null) ? 0 : value;
                value = parseInt(value);
                break;
            case 'color':
            case 'border-color':
            case 'background-color':
                value = (value === null) ? '' : this.app.color.normalize(value);
                break;
            case 'align':
                value = (value === null) ? this.opts.editor.align : value;
                break;
            case 'valign':
                value = (value === null) ? 'none' : value;
                break;
            case 'background-size':
                if (value === null) {
                    value = 'auto';
                }
                else if (value === false) {
                    value = 'cover';
                }

                value = (value === 'auto');
                break;
            case 'font-weight':
                value = (value === null) ? 'normal' : value;
                value = (value === 'bold') ? true : value;
                break;
            case 'text-decoration':
                value = (value === null) ? 'none' : value;
                value = (value === 'underline') ? true : value;
                break;
        }

        return value;
    },
    setter: function(name, value) {
        switch (name) {
            case 'padding':
            case 'alt':
            case 'href':
                value = new String(value).trim();
                break;
            case 'margin':
                value = new String(value).trim();
                value = (value === '') ? 0 : value;
                break;
            case 'color':
            case 'background-color':
                value = new String(value).trim();
                value = (value !== '' && value.indexOf('#') === -1) ? '#' + value : value;
                break;
            case 'border':
                var arr = value.split(' ');
                value = (parseInt(arr[0]) === 0 || arr[2] === '') ? '' : value;
                break;
            case 'width':
            case 'height':
            case 'font-size':
            case 'border-radius':
                value = this.number(value, 'px');
                break;
            case 'background-size':
                value = (value === true || value === 'auto') ? 'auto' : 'cover';
                break;
            case 'font-weight':
                value = (value === true || value === 'bold') ? 'bold' : 'normal';
                break;
            case 'font-style':
                value = (value === true || value === 'italic') ? 'italic' : 'normal';
                break;
            case 'text-decoration':
                value = (value === true || value === 'underline') ? 'underline' : 'none';
                break;
        }

        return value;
    },
    number: function(width, suffix) {
        return (width.search('%') !== -1) ? width : ((suffix) ? parseInt(width) + suffix : parseInt(width));
    }
});
Revolvapp.add('module', 'content', {
    init: function() {},
    paste: function(e) {
        // instance
        var instance = this.app.component.get();
        var type = instance.getType();
        var clipboard = (e.clipboardData  || e.originalEvent.clipboardData);
        var url = clipboard.getData('URL');
        var html = (this._isClipboardPlainText(clipboard)) ? clipboard.getData("text/plain") : clipboard.getData("text/html");
        var isMsWord = this._isHtmlMsWord(html);

        // get safari anchor links
        html = (!url || url === '') ? html : url;

        // clean
        html = this.removeDoctype(html);
        html = this.removeComments(html);
        html = this.removeTags(html, this.opts.tags.denied);

        // trim
        html = html.trim();

        // clean gdocs
        html = this._cleanGDocs(html);

        // create wrapper
        html = this.app.utils.wrap(html, function($w) {
            // clean apple space
            $w.find('.Apple-converted-space').unwrap();

            // remove block tags
            $w.find(this.opts.tags.block.join(',')).append('<br>').unwrap();

            // remove inline style
            $w.find(this.opts.tags.inline.join(',')).removeAttr('style');

            // remove empty span
            $w.find('span').each(this._removeEmptySpan.bind(this));

        }.bind(this));

        // remove tags
        var exceptedTags;
        var types1 = ['text', 'list', 'table-cell']
        var types2 = ['heading', 'link', 'button']
        if (types1.indexOf(type) !== -1) {
            exceptedTags = this.opts.tags.inline.concat(['br']);
            html = this.parseHtmlLinks(instance.$source, html, instance);
        }
        else if (types2.indexOf(type) !== -1) {
            exceptedTags = this.app.utils.removeFromArrayByValue(this.opts.tags.inline, 'a');
        }

        if (isMsWord) {
            html = html.replace(/\n/g, ' ');
            html = html.replace(/<!--\[if !supportLists\]-->([\s\S]*?)<!--\[endif\]-->/gi, '');
        }

        html = this._removeTagsExcept(html, this.app.utils.removeFromArrayByValue(exceptedTags, 'span'));
        html = this.removeComments(html);

        // nl to br
        if (!isMsWord) {
            html = this._replaceNlToBr(html);
        }

        // remove br on the end
        html = html.replace(/<br\s?\/?>$/gi, '');
        html = this.app.utils.removeInvisibleChars(html);

        // insert
        this.app.insertion.insertFromPaste(html, 'end');
    },

    // remove
    removeTemplateUtils: function(template) {
        template = this.app.utils.wrap(template, this.decodeVars.bind(this));
        return template.replace(/\sactive="true"/gi, '');
    },
    removeDoctype: function(html) {
        return html.replace(new RegExp("<!doctype[^>]*>", 'gi'), '');
    },
    removeComments: function(html) {
        return html.replace(/<!--[\s\S]*?-->\n?/g, '');
    },
    removeTags: function(input, denied) {
        var re = (denied) ? /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi : /(<([^>]+)>)/gi;
        var replacer = (!denied) ? '' : function ($0, $1) {
            return denied.indexOf($1.toLowerCase()) === -1 ? $0 : '';
        };

        return input.replace(re, replacer);
    },

    // parse
    parseHtmlLinks: function($source, html, instance) {
        var self = this;
        html = this.app.utils.wrap(html, function($w) {
            $w.find('a').each(function($node) {
                var data = instance.getLinkData($source);

                for (var key in data) {
                    self.setLinkCssProp($node, key, data[key]);
                }

                var href = $node.attr('href');
                href = self.replaceToHttps('href', href);

                $node.attr({ 'target': '_blank', 'href': href });
                var style = $node.attr('style');
                if (style) {
                    style = style.replace(/"/g, "'");
                    $node.attr('style', style);
                }
            });
        });


        return html;
    },
    setLinkCssProp: function($node, name, value) {
        var curValue = $node.css(name);
        if (!curValue) {
            $node.css(name, value);
        }
    },

    // decode
    decodeVars: function($el) {
        var delims = this.opts.editor.delimiters;
        $el.find('re-var').each(function($node) {
            $node.replaceWith($node.html());
        }.bind(this));

        return $el;
    },
    decodeVarsEntities: function(html) {
        if (this.opts.editor.delimiters) {
            var delims = this.opts.editor.delimiters;
            for (var key in delims) {
                var matches = html.match(new RegExp(delims[key][0] + '([\\w\\W]*?)' + delims[key][1], 'g'));
                if (matches) {
                    for (var i = 0; i < matches.length; i++) {
                        html = html.replace(matches[i], this.app.content.decodeEntities(matches[i]));
                    }
                }
            }
        }

        return html;
    },
    decodeEntities: function(str) {
        return String(str).replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&amp;/g, '&');
    },

    // replace
    replaceToHttps: function(name, value) {
        return (this.opts.editor.https && (name === 'href' || name === 'src')) ? value.replace('http://', 'https://') : value;
    },

    // empty
    isEmptyHtml: function(html, keepbr) {
        html = this.removeInvisibleChars(html);
        html = html.replace(/&nbsp;/gi, '');
        html = html.replace(/<\/?br\s?\/?>/g, ((keepbr) ? 'br' : ''));
        html = html.replace(/\s/g, '');
        html = html.replace(/^<p>[^\W\w\D\d]*?<\/p>$/i, '');
        html = html.replace(/^<div>[^\W\w\D\d]*?<\/div>$/i, '');
        html = html.replace(/<hr(.*?[^>])>$/i, 'hr');
        html = html.replace(/<iframe(.*?[^>])>$/i, 'iframe');
        html = html.replace(/<source(.*?[^>])>$/i, 'source');

        // remove empty tags
        html = html.replace(/<[^\/>][^>]*><\/[^>]+>/gi, '');
        html = html.replace(/<[^\/>][^>]*><\/[^>]+>/gi, '');

        // trim
        html = html.trim();

        return (html === '');
    },

    // extract
    extractHtmlFromCaret: function(el) {
        el = this.dom(el).get();
        var range = this.app.selection.getRange();
        if (range) {
            var clonedRange = range.cloneRange();
            clonedRange.selectNodeContents(el);
            clonedRange.setStart(range.endContainer, range.endOffset);

            return clonedRange.extractContents();
        }
    },

    // private
    _isHtmlMsWord: function(html) {
        return html.match(/class="?Mso|style="[^"]*\bmso-|style='[^'']*\bmso-|w:WordDocument/i);
    },
    _isClipboardPlainText: function(clipboard) {
        var text = clipboard.getData("text/plain");
        var html = clipboard.getData("text/html");

        if (text && html) {
            var element = document.createElement("div");
            element.innerHTML = html;

            if (element.textContent === text) {
                return !element.querySelector(":not(meta)");
            }
        }
        else {
            return (text !== null);
        }
    },
    _removeEmptySpan: function($node) {
        if ($node.get().attributes.length === 0) {
            $node.unwrap();
        }
    },
    _removeTagsExcept: function(input, except) {
        if (except === undefined) return input.replace(/(<([^>]+)>)/gi, '');

        var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi;
        return input.replace(tags, function($0, $1) {
            return except.indexOf($1.toLowerCase()) === -1 ? '' : $0;
        });
    },
    _cleanGDocs: function(html) {
        // remove google docs markers
        html = html.replace(/<b\sid="internal-source-marker(.*?)">([\w\W]*?)<\/b>/gi, "$2");
        html = html.replace(/<b(.*?)id="docs-internal-guid(.*?)">([\w\W]*?)<\/b>/gi, "$3");
        html = html.replace(/<br[^>]*>/gi, '<br>');

        html = html.replace(/<span[^>]*(font-style:\s?italic;\s?font-weight:\s?bold|font-weight:\s?bold;\s?font-style:\s?italic)[^>]*>([\w\W]*?)<\/span>/gi, '<b><i>$2</i></b>');
        html = html.replace(/<span[^>]*(font-style:\s?italic;\s?font-weight:\s?600|font-weight:\s?600;\s?font-style:\s?italic)[^>]*>([\w\W]*?)<\/span>/gi, '<b><i>$2</i></b>');
        html = html.replace(/<span[^>]*(font-style:\s?italic;\s?font-weight:\s?700|font-weight:\s?700;\s?font-style:\s?italic)[^>]*>([\w\W]*?)<\/span>/gi, '<b><i>$2</i></b>');
        html = html.replace(/<span[^>]*font-style:\s?italic[^>]*>([\w\W]*?)<\/span>/gi, '<i>$1</i>');
        html = html.replace(/<span[^>]*font-weight:\s?bold[^>]*>([\w\W]*?)<\/span>/gi, '<b>$1</b>');
        html = html.replace(/<span[^>]*font-weight:\s?700[^>]*>([\w\W]*?)<\/span>/gi, '<b>$1</b>');
        html = html.replace(/<span[^>]*font-weight:\s?600[^>]*>([\w\W]*?)<\/span>/gi, '<b>$1</b>');

        html = html.replace(/<p[^>]*>\s<\/p>/gi, '');

        return html;
    },
    _replaceNlToBr: function(html) {
        return html.replace(/\n/g, '<br />');
    }
});
Revolvapp.add('module', 'image', {
    init: function() {},
    set: function(url) {
        var instance = this.app.component.get();
        if (instance && instance.getType() === 'image') {
            instance.setImage(url);
            this.app.editor.adjustHeight();
            this.app.broadcast('image.change', { response: { url: url } });
        }
    },
    removeBackground: function() {
        var instance = this.app.component.get() || this.app.editor.getBodyInstance();
        var stack = this.app.popup.getStack();

        stack.setData({ 'background-image': '' });
        instance.setData({ 'background-image': '' });

        // event
        this.app.broadcast('image.background.remove');
    },
    successBackground: function(response) {
        this.app.broadcast('image.background.change', { response: response });
    },
    successDropUpload: function(response) {
        var instance = this.app.component.get();
        instance.setImage(response.url);

        this.app.editor.adjustHeight();
        this.app.broadcast('image.change', { response: response });
    },
    successUpload: function(response) {
        this.app.editor.adjustHeight();
        this.app.broadcast('image.change', { response: response });
    },
    successSocialUpload: function(response) {
        this.app.editor.adjustHeight();
        this.app.broadcast('image.change', { response: response });
    },
    error: function(response) {
        this.app.broadcast('image.upload.error', { response: response });
    }
});
Revolvapp.add('module', 'parser', {
    parse: function() {
        var template = this.app.editor.getTemplateSourceElement().html();
        var $content = this.dom('<div>');

        var $el = this.dom('<div>').html(template);
        this.app.editor.setTemplateElement($el);

        // render html
        var $html = $el.children().first();
        var $head = $html.find('re-head');
        var $body = $html.find('re-body');
        var $options = $html.find('re-options');
        var $headings = $html.find('re-headings');
        var htmlInstance = this._createTag('html', $html, true);

        var html = $body.html();
        if (this.opts.editor.delimiters) {
            var stored = this._store(html);
            html = stored.html;

            var delims = this.opts.editor.delimiters;
            for (var key in delims) {
                html = html.replace(new RegExp(delims[key][0], 'g'), '<re-var>' + delims[key][0]);
                html = html.replace(new RegExp(delims[key][1], 'g'), delims[key][1] + '</re-var>');
            }

            // restore tags
            html = this._restoreReplaced(stored.data, html);
            html = this._restoreReplaced(stored.data, html);
        }

        $body.html(html);

        this._parseOptions($options);
        this._parseHeadings($headings);

        $content.append(htmlInstance.$element);

        // nodes
        this._parse($head, htmlInstance.$element);
        this._parse($body, htmlInstance.$element, true);

        // default styles
        this._createDefaultStyles($content);

        // get
        var doctype = this._createDoctype();
        var code = $content.html();

        code = doctype + code;

        this._setHtml(code);
        this._renderContent($body.children());
    },
    unparse: function(tidy) {
        var $doc = this.app.editor.getDoc().clone();

        var $body = $doc.find('body');
        var $table = $body.find('table').first();
        var $div = this.dom('<div>');

        $div.css({
            'background-color': $body.get().style.backgroundColor,
            'background-image': $body.get().style.backgroundImage,
            'background-size': $body.get().style.backgroundSize
        });

        var bg = $body.attr('background');
        if (bg) {
            $div.attr('background', $body.attr('background'));
        }

        $body.css({
            'background-image': '',
            'background-size': ''
        });
        $body.removeAttr('background');

        $table.wrap($div);

        var doc = $doc.get();

        this.app.content.decodeVars($doc);

        // clean
        this._transformTags($doc);
        this._removeUtils($doc);

        var html = doc.documentElement.outerHTML;

        html = (tidy === true) ? this.app.tidy.parse(html, 'html') : html;
        html = html.replace(/url\(&quot;(.*?)&quot;\)/gi, "url('$1')");
        html = html.replace(/&quot;(.*?)&quot;/gi, "'$1'");
        html = this.app.color.replaceRgbToHex(html);

        // broadcast
        var event = this.app.broadcast('editor.unparse', { html: html });
        html = event.get('html');
        html = this.app.content.decodeVarsEntities(html);
        html = this.app.utils.removeInvisibleChars(html);

        // html
        return this._getDoctype(doc) + '\n' + html;
    },
    render: function($nodes, $parent) {
        this._parse($nodes, $parent);
    },

    // parse
    _parse: function($nodes, $parent, stop) {
        $nodes.each(function($node) {
            var node = $node.get();
            var tag = node.tagName.toLowerCase().replace('re-', '');
            var instance;
            if (this.opts._tags.indexOf(tag) !== -1) {
                instance = this._createTag(tag, $node);
                if (tag === 'text') {
                    instance._parseHtmlLinks(instance.$source, instance.$element, instance);
                }
                if (!stop && this.opts._nested.indexOf(tag) !== -1) {
                    this._parse($node.children(), instance.getTarget());
                }
            }
            else {
                instance = { $element: $node };
            }

            if (tag === 'preheader') {
                this.app.editor.getBody().prepend(instance.$element);
            }
            else {
                $parent.append(instance.$element);
            }
        }.bind(this));
    },
    _parseOptions: function($options) {
        if ($options.length === 0) return;

        var str = $options.text().trim();
        var options = JSON.parse(str);

        // extend styles from template
        this.opts.styles = $RE.extend(true, this.opts.styles, options);
    },
    _parseHeadings: function($headings) {
        if ($headings.length === 0) return;

        var str = $headings.text().trim();
        var headings = JSON.parse(str);

        // extend styles from template
        this.opts.headings = $RE.extend(true, this.opts.headings, headings);
    },

    // create
    _createDoctype: function() {
        return this.opts.editor.doctype + '\n';
    },
    _createDefaultStyles: function($content) {
        var $default = this.dom('<style>');
        $default.attr('type', 'text/css');
        $default.html(this.opts._styles);

        var $head = $content.find('head');
        var $style = $head.find('style');

        if ($style.length !== 0) {
            $style.first().before($default);
        }
        else {
            $head.append($default);
        }

        // mso styles
        $head.append(this.opts._msoStyles);
    },
    _createTag: function(type, $source) {
        $source = $source || this.dom('<re-' + type +'>');

        // create
        return this.app.create('tag.' + type, $source);
    },

    // set
    _setHtml: function(html) {
        var doc = this.app.editor.getDocNode();

        // write html
        doc.open();
        doc.write(html);
        doc.close();
    },

    // render
    _renderContent: function($nodes) {
        var $body = this.app.editor.getBodyTarget();

        this._parse($nodes, $body);
        this.app.editor._load();
    },

    // get
    _getDoctype: function(doc) {
        var node = doc.doctype;

        return "<!DOCTYPE " + node.name
         + (node.publicId ? ' PUBLIC "' + node.publicId + '"' : '')
         + (!node.publicId && node.systemId ? ' SYSTEM' : '')
         + (node.systemId ? ' "' + node.systemId + '"' : '') + '>';
    },

    // remove
    _removeUtils: function($doc) {
        var $elms = $doc.find('[data-' + this.prefix + '-type]');

        $elms.each(function($node) {
            var node = $node.get();
            var line = node.style.lineHeight;
            var size = node.style.fontSize;

            if (line && size && line !== '0' && line.search('px') === -1) {
                node.style.lineHeight = Math.ceil(parseFloat(line) * parseInt(size.replace('px', ''))) + 'px';
            }
        });

        $elms.removeAttr('data-' + this.prefix + '-type contenteditable noneditable unremovable');
        $elms.removeClass(this.prefix + '-element-active ' + this.prefix + '-element-hover');

        $doc.find('.' + this.prefix + '-editable').removeAttr('contenteditable').removeClass(this.prefix + '-editable');
        $doc.find('[data-gramm_editor]').removeAttr('data-gramm_editor');
        $doc.find('.' + this.prefix + '-image-placeholder, .' + this.prefix + '-social-placeholder, .' + this.prefix + '-plus-button').remove();
        $doc.find('.' + this.prefix + '-empty-layer').removeClass(this.prefix + '-empty-layer');
        $doc.find('.' + this.prefix + '-css, .rex-block-hidden-text').remove();
        $doc.find('p').each(function($node) {
            this.app.element.removeEmptyAttrs($node, ['class']);
        }.bind(this));
    },
    _removeEmptyLink: function($node) {
        var href = $node.attr('href');
        if (!href || href === '' || href === '#') {
            $node.unwrap();
        }
    },

    // transform
    _transformTags: function($doc) {
        $doc.find('[data-' + this.prefix + '-type=menu-item]').each(this._transformItemToSpan.bind(this));
        $doc.find('[data-' + this.prefix + '-type=image] a,[data-' + this.prefix + '-type=heading] a').each(this._removeEmptyLink.bind(this));
        $doc.find('[data-' + this.prefix + '-type=heading]').each(this._transformHeadings.bind(this));
    },
    _transformItemToSpan: function($node) {
        var href = $node.attr('href');
        if (!href || href === '' || href === '#') {
            $node.removeAttr('href');
            $node = this.app.element.replaceToTag($node, 'span');
        }
    },
    _transformHeadings: function($node) {
        for (var i = 1; i < 7; i++) {
            var tag = 'h' + i;
            if ($node.hasClass(tag)) {
                this.app.element.replaceToTag($node, tag);
            }
        }
    },
    _store: function(html) {
        // store tags
        var tags = ['a', 're-image', 're-link', 're-button', 're-heading', 're-text', 're-list-item', 're-table-cell'];
        var stored = [];
        var z = 0;

        // store tags
        for (var i = 0; i < tags.length; i++) {
            var reTags = '<' + tags[i] + '[^>]*>([\\w\\W]*?)</' + tags[i] + '>';
            var matched = html.match(new RegExp(reTags, 'gi'));

            if (matched !== null) {
                for (var y = 0; y < matched.length; y++) {
                    html = html.replace(matched[y], '#####replaceparse' + z + '#####');
                    stored.push(matched[y]);
                    z++;
                }
            }
        }

        return { data: stored, html: html };
    },
    _restoreReplaced: function(stored, html) {
        for (var i = 0; i < stored.length; i++) {
            html = html.replace('#####replaceparse' + i + '#####', stored[i]);
        }

        return html;
    }
});
Revolvapp.add('module', 'input', {
    handle: function(event) {
        if (!this.app.component.is()) return;

        var e = event.get('e');
        var instance = this.app.component.get();
        var $el, type;

        if (event.is('tab') || event.is('down')) {
            var next = instance.getNext();
            var isEnd = (instance.isEditable()) ? this.app.caret.is(instance.getEditableElement(), 'end') : true;
            next = this._traverseParent(next, instance);

            if (next && isEnd) {
                e.preventDefault();
                $el = next.getElement();
                this.app.component.set($el);
            }
        }
        else if (event.is('up')) {
            var prev = instance.getPrev();
            var isStart = (instance.isEditable()) ? this.app.caret.is(instance.getEditableElement(), 'start') : true;
            prev = this._traverseParent(prev, instance);

            if (prev && isStart) {
                e.preventDefault();
                $el = prev.getElement();
                this.app.component.set($el);
            }
        }
        else if ((event.is('delete') || event.is('backspace'))) {
            if (instance.isEditable()) {
                type = instance.getType();
                if (type === 'list') {
                    var $items = instance.getElement().find('li');
                    var current = this.app.selection.getBlock();
                    if ($items.length === 1 && this.app.content.isEmptyHtml(current.innerHTML)) {
                        e.preventDefault();
                        return;
                    }
                }
            }
            else {
                e.preventDefault();
                this.app.component.remove();
            }
        }
        else if (event.is('enter')) {
            type = instance.getType();
            if (type === 'list') {
                return;
            }

            e.preventDefault();

            if (!instance.isEditable()) return;

            var selectionTypes = ['text', 'heading', 'link', 'button'];
            var enterTypes = ['text', 'heading', 'table-cell'];
            var sel = this.app.selection.get();

            // selected
            if (!sel.collapsed && selectionTypes.indexOf(type) !== -1) {
                sel.range.deleteContents();
            }
            // insert br
            else if (enterTypes.indexOf(type) !== -1) {
                this.app.insertion.insertBreakline();
            }

        }
    },
    handleTextareaTab: function(e) {
        if (e.keyCode !== 9) return true;

        e.preventDefault();

        var el = e.target;
        var val = el.value;
        var start = el.selectionStart;

        el.value = val.substring(0, start) + "    " + val.substring(el.selectionEnd);
        el.selectionStart = el.selectionEnd = start + 4;
    },

    // private
    _traverseParent: function(el, instance) {
        var type = instance.getType();
        var types = ['block', 'column'];

        if (!el && types.indexOf(type) === -1) {
            var block = instance.getParent('block');
            var column = instance.getParent('column');

            el = (column) ? column : block;
        }
        else if (!el && type === 'column') {
            el = instance.getParent('grid');
        }

        return el;
    }
});
Revolvapp.add('class', 'tool.input', {
    mixins: ['tool'],
    type: 'input',
    input: {
        tag: 'input',
        type: 'text',
        classname: '-form-input'
    },

    // private
    _buildInput: function() {
        this.$tool.append(this.$input);
    }
});
Revolvapp.add('class', 'tool.textarea', {
    mixins: ['tool'],
    type: 'textarea',
    input: {
        tag: 'textarea',
        classname: '-form-textarea'
    },
    setFocus: function() {
        this.$input.focus();
        this.$input.get().setSelectionRange(0, 0);
        this.$input.scrollTop(0);
    },

    // private
    _buildInput: function() {
        if (this._has('rows')) {
            this.$input.attr('rows', this._get('rows'))
        }

        this.$input.attr('data-gramm_editor', false);
        this.$tool.append(this.$input);
    }
});
Revolvapp.add('class', 'tool.select', {
    mixins: ['tool'],
    type: 'select',
    input: {
        tag: 'select',
        classname: '-form-select'
    },

    // private
    _buildInput: function() {
        for (var value in this.obj.options) {
            var $option = this.dom('<option>');
            $option.val(value);
            $option.html(this.lang.parse(this.obj.options[value]));

            this.$input.append($option);
        }

        this.$tool.append(this.$input);
    }
});
Revolvapp.add('class', 'tool.checkbox', {
    mixins: ['tool'],
    type: 'checkbox',
    input: {
        tag: 'input',
        type: 'checkbox',
        classname: '-form-checkbox'
    },
    getValue: function() {
        return this.$input.val();
    },

    // private
    _buildInput: function() {
        this.$box = this.dom('<label>').addClass(this.prefix + '-form-checkbox-item');
        this.$box.append(this.$input);

        // checkbox text
        if (this._has('text')) {
            var $span = this.dom('<span>').html(this.lang.parse(this.obj.text));
            this.$box.append($span);
        }

        this.$tool.append(this.$box);
    }
});
Revolvapp.add('class', 'tool.segment', {
    mixins: ['tool'],
    type: 'segment',
    input: {
        tag: 'input',
        type: 'hidden',
        classname: '-form-input'
    },
    setValue: function(value) {
        this.$segment.find('.' + this.prefix + '-form-segment-item').removeClass('active');
        this.$segment.find('[data-segment=' + value + ']').addClass('active');
        this.$input.val(value);
    },

    // private
    _buildInput: function() {
        this.$segment = this.dom('<div>').addClass(this.prefix + '-form-segment');

        var segments = this.obj.segments;
        for (var name in segments) {
            var $segment = this.dom('<span>').addClass(this.prefix + '-form-segment-item');
            $segment.attr('data-segment', name).on('click', this._catchSegment.bind(this));

            if (Object.prototype.hasOwnProperty.call(segments[name], 'icon')) {
                $segment.html(segments[name].icon);
            }
            else {
                $segment.addClass(this.prefix + '-icon-' + segments[name].prefix + '-' + name);
            }

            this.$segment.append($segment);
        }

        this.$segment.append(this.$input);
        this.$tool.append(this.$segment);
    },
    _catchSegment: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $item = this.dom(e.target).closest('.' + this.prefix + '-form-segment-item');
        var value = $item.attr('data-segment');

        this.$segment.find('.' + this.prefix + '-form-segment-item').removeClass('active');
        $item.addClass('active');
        this.$input.val(value);

        // call setter
        this.app.api(this.setter, this.popup);
    }
});
Revolvapp.add('class', 'tool.color', {
    mixins: ['tool'],
    type: 'color',
    input: {
        tag: 'input',
        type: 'text',
        classname: '-form-input'
    },
    setValue: function(value) {
        this.$input.val(value);
        this.$select.css('background-color', value);

        if (this.$picker) {
            this.setColor(value);
        }

        if (value && this.$checkbox) {
            this.$checkbox.attr('checked', true);
        }
    },
    setColor: function(color) {
        this.$picker.attr('data-current-color', color);
        this.$picker.find('.' + this.prefix + '-color').removeClass('active');
        this.$picker.find('.' + this.prefix + '-color').each(function($node) {
            var value = $node.attr('data-value');
            // active
            if (value === color) {
                $node.addClass('active');
                $node.css('color', this.app.color.invert(color));
            }
        }.bind(this));
    },


    // private
    _buildInput: function() {
        this.$box = this.dom('<div>').addClass(this.prefix + '-form-container-flex ' + this.prefix + '-form-container-color');
        this.$select = this.dom('<span>').addClass(this.prefix + '-form-color-select');
        this.$checkbox = this.dom('<input>').addClass(this.prefix + '-form-checkbox').attr('type', 'checkbox');

        this.$input.css('max-width', '90px');
        this.$input.on('keydown blur', this._changeColorSelect.bind(this));

        if (this._has('picker')) {
            this.$picker = this._createPicker();
            this.$tool.append(this.$picker);
        }
        else {
            this.$select.addClass(this.prefix + '-form-color-select-pointer');
            this.$select.on('click', this._buildColorpicker.bind(this));
        }

        if (this.name === 'background-color') {
            this.$box.append(this.$checkbox);
            this.$checkbox.on('change', this._changeColorState.bind(this));
        }

        this.$box.append(this.$select);
        this.$box.append(this.$input);
        this.$tool.append(this.$box);

        if (this._has('picker')) {
            this._buildColors();
        }
    },
    _buildColors: function() {
        this.$picker.html('');
        for (var key in this.opts.colors) {
            var $div = this.dom('<div class="' + this.prefix + '-form-colors">');

            for (var i = 0; i < this.opts.colors[key].length; i++) {
                var color = this.opts.colors[key][i];
                var $span = this._createColor(color, key, i);
                if (color === '#fff' || color === '#ffffff') {
                    $span.addClass(this.prefix + '-form-color-contrast');
                }

                $div.append($span);
            }

            this.$picker.append($div);
        }
    },
    _buildColorpicker: function(e) {
        e.preventDefault();
        e.stopPropagation();

        this.$picker = this._createPicker();
        var stack = this.app.popup.add('colorpicker', {
            title: '## popup.pick-color ##',
            width: '320px'
        });
        stack.getBody().append(this.$picker);

        this._buildColors();
        this.setColor(this.$input.val());

        stack.open();
    },
    _createPicker: function() {
        return this.dom('<div>').addClass(this.prefix + '-form-colorpicker');
    },
    _createColor: function(color, key, i) {
        var $span = this.dom('<span>').addClass(this.prefix + '-color').css('background-color', color);
        $span.attr({ 'title': key + '-' + i, 'data-value': color });
        $span.on('mouseover', this._inColor.bind(this));
        $span.on('mouseout', this._outColor.bind(this));
        $span.on('click', this._setColor.bind(this));

        return $span;
    },
    _inColor: function(e) {
        var $color = this.dom(e.target);
        var value = $color.attr('data-value');

        this._setColorToInput(value);
    },
    _outColor: function() {
        this._setColorToInput(this.$picker.attr('data-current-color'));
    },
    _setColorToInput: function(value) {
        this.$input.val(value);
        this.$select.css('background-color', value);
    },
    _setColor: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $color = this.dom(e.target);
        var value = $color.attr('data-value');

        this.$picker.attr('data-current-color', value);
        this.$picker.find('.' + this.prefix + '-color').removeClass('active');
        $color.addClass('active');
        $color.css('color', this.app.color.invert(value));

        this._setColorToInput(value);

        if (this.setter) {
            this.app.api(this.setter, this.popup);
        }

        if (this._has('picker')) {
            this.app.popup.close();
        }
        else {
            var stack = this.app.popup.getStack();
            stack.collapse();
        }
    },
    _changeColorSelect: function(e) {
        if (e.type === 'keydown' && e.which !== 13) return;
        if (e.type === 'keydown') e.preventDefault();

        var value = this.$input.val();
        value = this.app.color.normalize(value);

        this.$input.val(value);
        this.$select.css('background-color', value);

        if (this.picker) {
            this.picker.setColor(value);
        }

        this.$checkbox.attr('checked', (value !== ''));
    },
    _changeColorState: function(e) {
        e.preventDefault();
        e.stopPropagation();

        var state = this.$checkbox.attr('checked');
        var value = (state) ? '#ffffff' : '';

        this.setValue(value);
        this.app.api(this.setter, this.stack);
    }
});
Revolvapp.add('class', 'tool.number', {
    mixins: ['tool'],
    type: 'number',
    input: {
        tag: 'input',
        type: 'number',
        classname: '-form-input'
    },

    // private
    _buildInput: function() {
        this.$input.attr('min', 0).css('max-width', '65px');
        this.$tool.append(this.$input);
    }
});
Revolvapp.add('class', 'tool.upload', {
    mixins: ['tool'],
    type: 'upload',
    input: {
        tag: 'input',
        type: 'hidden',
        classname: '-form-input'
    },
    setValue: function(value) {
        value = (value) ? value : '';

        if (this.upload) {
            this.upload.setImage(value);
        }

        this.$input.val(value);
    },

    // private
    _buildInput: function() {
        // input
        this.$tool.append(this.$input);

        if (this._isDirect()) {
            this._buildDirectUrl();
        }

        if (this._isUpload()) {
            if (this._isDirect()) {
                this._buildOrSection();
            }
            this._buildUpload();
        }
    },
    _buildOrSection: function() {
        var $div = this.dom('<div class="' + this.prefix + '-upload-or">').html(this.lang.get('placeholders.or-drag-and-drop-the-image'));
        this.$tool.append($div);
    },
    _buildUpload: function() {
        this.$upload = this.dom('<input>').attr('type', 'file');
        this.$tool.append(this.$upload);

        var params = $RE.extend({}, this.obj.upload, {
            url: this.opts.image.upload,
            name: this.opts.image.name,
            data: this.opts.image.data,
            placeholder: this.opts.placeholders.upload,
            multiple: this.opts.image.multiple,
            box: true,
            hidden: false
        });

        this.upload = this.app.create('upload', this.$upload, params, {
            instance: this,
            method: 'trigger'
        });
    },
    _buildDirectUrl: function() {
        this.$directInput = this.dom('<input>').addClass(this.prefix + '-form-input');
        this.$directInput.attr({ 'type': 'text', 'placeholder': this.lang.get('placeholders.paste-url-of-image') });
        this.$directInput.on('input blur', this._catchDirectInput.bind(this));

        if (!this._isUpload()) {
            this.$directLabel = this.dom('<label>').addClass(this.prefix + '-form-label').html(this.lang.get('form.url'));
            this.$tool.append(this.$directLabel);

            // catch background image
            if (this._isLayerType()) {
                var src = this.data['background-image'];
                src = (typeof src === 'undefined') ? '' : src;

                this.data.src = src;
                this.$directInput.val(src);
            }
        }

        this.$tool.append(this.$directInput);
    },
    _isUpload: function() {
        var o = this.opts.image;

        return (o && o.upload);
    },
    _isDirect: function() {
        var o = this.opts.image;

        return (this._has('direct') && o && o.url);
    },
    _isLayerType: function() {
        var type = this.instance.getType();
        return (type !== 'image' && type !== 'social-item');
    },
    _catchDirectInput: function(e) {
        if (e.type === 'keydown' && e.which !== 13) return;
        if (e.type === 'keydown') e.preventDefault();

        var value = this.$directInput.val();
        if (value === '') {
            if (this._isUpload() || !this._isLayerType()) return;
        }

        this.trigger(value);
    }
});
Revolvapp.add('class', 'tag.html', {
    mixins: ['tag'],
    type: 'html',
    create: function() {
        this.$element = this.dom('<html>').attr(this.params);
    },
    build: function() {
        this.params = {
            'xmlns': 'http://www.w3.org/1999/xhtml',
            'dir': this.opts.direction
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.head', {
    mixins: ['tag'],
    type: 'head',
    create: function() {
        this.$element = this.dom('<head>');
        this.$element.append('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
        this.$element.append('<meta name="viewport" content="width=device-width, initial-scale=1.0" />');
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.title', {
    mixins: ['tag'],
    type: 'title',
    create: function() {
        this.$element = this.dom('<title>').html(this.params.html);
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.font', {
    mixins: ['tag'],
    type: 'font',
    create: function() {
        this.$element = this.dom('<link>').attr({ 'href': this.params.href, 'rel': 'stylesheet' });
    },
    build: function() {
        this.params = {
            href: this.$source.attr('href')
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.style', {
    mixins: ['tag'],
    type: 'style',
    create: function() {
        var html = this.app.content.decodeEntities(this.params.html);
        this.$element = this.dom('<style>').html(html).attr('type', 'text/css');
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.body', {
    mixins: ['tag'],
    type: 'body',
    toolbar: {
        'shortcut': { title: '## buttons.shortcuts ##', command: 'shortcut.popup', observer: 'shortcut.observePopup' },
        'mobile': { title: '## buttons.mobile-view ##', command: 'editor.toggleView' },
        'code': { title: '## buttons.html ##',  command: 'source.toggle', observer: 'source.checkCodeView' },
        'background': { title: '## buttons.background ##', command: 'editor.popup', color: true, observer: 'editor.observe' },
        'tune': { title: '## buttons.settings ##', command: 'editor.popup' }
    },
    forms: {
        background: {
           'background-color': {
                type: 'color',
                picker: true
            }
        },
        backgroundimage: {
            'background-size': {
                type: 'checkbox',
                text: '## form.pattern ##'
            },
            'background-image': {
                type: 'upload',
                direct: true,
                observer: 'component.checkImageChange',
                upload: {
                    success: 'image.successBackground',
                    error: 'image.error',
                    remove: 'image.removeBackground'
                }
            }
        },
        settings: {
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<body>');
        this.$element.css({ 'font-family': this.opts.editor.font, 'margin': 0, 'padding': 0 });

        // container
        this._createTableContainer(this.params.width);
        this.$table.addClass('body');
        this.$cell.attr('align', 'center');
        this.$element.append(this.$table);
    },
    build: function() {
        this.params = {
            width: '100%'
        };

        this.data = {
            'background-color': { target: ['element'] },
            'background-image': { target: ['element'] },
            'background-size': { target: ['element'] },
            'class': { target: ['cell'] },
            'padding': { target: ['cell'] }
        };
    },
    render: function() {
        return this.$cell;
    }
});
Revolvapp.add('class', 'tag.preheader', {
    mixins: ['tag'],
    type: 'preheader',
    create: function() {
        this.$element = this.dom('<span>').html(this.params.html);
        this.$element.css({
            'color': 'transparent',
            'display': 'none',
            'height': 0,
            'max-height': 0,
            'max-width': 0,
            'opacity': 0,
            'overflow': 'hidden',
            'visibility': 'hidden',
            'width': 0
        });

        var style = this.$element.attr('style');
        if (style !== null) {
            style = style.trim();
            if (style.length > 0 && style.substr(-1) !== ";") {
                style += "; ";
            }
        }
        else {
            style = "";
        }

        this.$element.attr('style', style + ' mso-hide: all;');
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.header', {
    mixins: ['tag'],
    type: 'header',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    forms: {
        settings: {
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('header container');
    },
    build: function() {
        this.params = {
            width: this._getSourceWidth()
        };

        this.data = {
            'class': { target: ['cell'] },
            'width': { target: ['element'] },
            'padding': { target: ['cell'] },
            'background-color': { target: ['cell'] },
            'background-image': { target: ['cell'] },
            'background-size': { target: ['cell'] },
            'border': { target: ['cell'] },
            'border-radius': { target: ['cell'] },
            'box-shadow': { target: ['element'] }
        };
    },
    render: function() {
        return this.$cell;
    }
});
Revolvapp.add('class', 'tag.main', {
    mixins: ['tag'],
    type: 'main',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    forms: {
        settings: {
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('main container');
    },
    build: function() {
        this.params = {
            width: this._getSourceWidth()
        };

        this.data = {
            'class': { target: ['cell'] },
            'width': { target: ['element'] },
            'padding': { target: ['cell'] },
            'background-color': { target: ['cell'] },
            'background-image': { target: ['cell'] },
            'background-size': { target: ['cell'] },
            'border': { target: ['cell'] },
            'border-radius': { target: ['cell'] },
            'box-shadow': { target: ['element'] }
        };
    },
    render: function() {
        return this.$cell;
    }
});
Revolvapp.add('class', 'tag.footer', {
    mixins: ['tag'],
    type: 'footer',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    forms: {
        settings: {
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('footer container');
    },
    build: function() {
        this.params = {
            width: this._getSourceWidth()
        };

        this.data = {
            'class': { target: ['cell'] },
            'width': { target: ['element'] },
            'padding': { target: ['cell'] },
            'background-color': { target: ['cell'] },
            'background-image': { target: ['cell'] },
            'background-size': { target: ['cell'] },
            'border': { target: ['cell'] },
            'border-radius': { target: ['cell'] },
            'box-shadow': { target: ['element'] }
        };
    },
    render: function() {
        return this.$cell;
    }
});
Revolvapp.add('class', 'tag.container', {
    mixins: ['tag'],
    type: 'container',
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('container');
    },
    build: function() {
        this.params = {
            width: '100%'
        };

        this.data = {
            'class': { target: ['cell'] },
            'width': { target: ['element'] },
            'padding': { target: ['cell'] },
            'background-color': { target: ['cell'] },
            'background-image': { target: ['cell'] },
            'background-size': { target: ['cell'] },
            'border': { target: ['cell'] },
            'border-radius': { target: ['cell'] }
        };
    },
    render: function() {
        return this.$cell;
    }
});
Revolvapp.add('class', 'tag.block', {
    mixins: ['tag'],
    type: 'block',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            },
            'column-space': {
                type: 'number',
                label: '## form.column-space ##',
                observer: 'component.checkColumnSpacer'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('block');

        // safari crash fix
        var $span = this.dom('<span class="rex-block-hidden-text">').css({'font-size': '0px', 'position': 'absolute', 'left': '-9999px', 'height': 0, 'width': 0}).html('hidden text');
        this.$cell.append($span);
    },
    build: function() {
        this.params = {
            width: '100%'
        };

       this.data = {
            'align': { target: ['cell'] },
            'valign': { target: ['cell'] },
            'padding': { target: ['cell'] },
            'background-color': { target: ['cell'] },
            'background-image': { target: ['cell'] },
            'background-size': { target: ['cell'] },
            'border': { target: ['cell'] },
            'border-radius': { target: ['cell'] },
            'class': { target: ['cell'] },
            'color': { target: false, getter: 'getElementsTextColor', setter: 'setElementsTextColor', prop: this.getStyle('text', 'color') },
            'link-color': { target: false, getter: 'getElementsLinkColor', setter: 'setElementsLinkColor', prop: this.getStyle('link', 'color') },
            'column-space': { target: false, getter: 'getColumnSpace', setter: 'setColumnSpace' },
            'box-shadow': { target: ['element'] }
        };
    },
    render: function() {
        return this.$cell;
    },
    getColumnSpace: function() {
        var $el = this.getElements(['column-spacer']).first();
        return ($el.length === 0) ? null : $el.dataget('instance').getData('width');
    },
    setColumnSpace: function(value) {
        this.getElements(['column-spacer']).each(function($node) { $node.dataget('instance').setData({ 'width': value }); });
    },
    setAlign: function(value) {
        if (value === 'left') {
            this.$cell.removeAttr('align');
            this.$source.removeAttr('align');
        }
        else {
            this.$cell.attr('align', value);
            this.$source.attr('align', value);
        }

        var types = ['text', 'heading', 'link', 'menu', 'social'];
        this.getElements(types).each(function($node) { $node.dataget('instance').setData({ 'align': null }); });
        this.getElements(['column']).each(function($node) { $node.dataget('instance').setData({ 'align': value }); });
    }
});
Revolvapp.add('class', 'tag.spacer', {
    mixins: ['tag'],
    type: 'spacer',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'height': {
                type: 'number',
                label: '## form.height ##'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('spacer');
        this.$cell.css({ 'padding': 0, 'font-size': this.params.height, 'line-height': this.params.height });
        this.$cell.html('&nbsp;');
    },
    build: function() {
        this.params = {
            height: this.getStyle('spacer', 'height'),
            width: '100%'
        };

        this.data = {
            'height': { target: ['cell'], setter: 'setHeight', prop: this.params.height }
        };
    },
    render: function() {
        return this.$cell;
    },

    setHeight: function(value) {
        var html = (parseInt(value) === 0) ? '' : '&nbsp;';

        value = (parseInt(value) === 0) ? 1 : value;
        value = this.app.normalize.number(value, 'px');

        this.$cell.html(html);
        this.$cell.css({ 'height': value, 'font-size': value, 'line-height': value });
        this.$source.attr('height', value);
    }
});
Revolvapp.add('class', 'tag.divider', {
    mixins: ['tag'],
    type: 'divider',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'height': {
                type: 'number',
                label: '## form.height ##'
            },
            'width': {
                type: 'input',
                width: '65px',
                label: '## form.width ##'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$element.addClass('divider');
        this.$cell.css({ 'padding': 0, 'font-size': this.params.height, 'line-height': this.params.height });
        this.$cell.html('&nbsp;');
    },
    build: function() {
        this.params = {
            height: this.getStyle('divider', 'height'),
            width: '100%'
        };

        this.data = {
            'width': { target: ['element'], prop: this.params.width },
            'height': { target: ['cell'], setter: 'setHeight', prop: this.params.height },
            'background-color': { target: ['cell'], prop: this.getStyle('divider', 'background-color') }
        };
    },
    render: function() {
        return this.$cell;
    },

    setHeight: function(value) {
        this.$cell.css({ 'font-size': value, 'line-height': value });
        this.$source.attr('height', value);
    }
});
Revolvapp.add('class', 'tag.text', {
    mixins: ['tag'],
    type: 'text',
    editable: true,
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'link': { title: '## buttons.link ##',  command: 'link.popup' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            },
            'font-size': {
                type: 'number',
                label: '## form.text-size ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<p>').addClass('rex-editable');
        this.$element.css({ 'padding': 0, 'margin': 0, 'font-family': this.getStyle('text', 'font-family') });
        this.$element.html(this.params.html);
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'html': { target: ['element'] },
            'color': { target: ['element'], prop: this.getStyle('text', 'color') },
            'font-size': { target: ['element'], setter: 'setTextSize', prop: this.getStyle('text', 'font-size') },
            'line-height': { target: ['element'], prop: this.getStyle('text', 'line-height') },
            'link-color': { target: false, getter: 'getLinkColor', setter: 'setLinkColor', prop: this.getStyle('link', 'color') },
            'align': { target: ['element'], getter: 'getAlign' },
            'margin': { target: ['element'] },
            'class': { target: ['element'] },
            'font-weight': { target: ['element'] },
            'font-style': { target: ['element'] },
            'text-decoration': { target: ['element'] },
            'letter-spacing': { target: ['element'] },
            'text-transform': { target: ['element'] }
        };
    },
    render: function() {
        this._parseHtmlLinks(this.$source, this.$element, this);
        return this.$element;
    },
    getLinkColor: function() {
        var $a = this.$element.find('a').first();
        var color = ($a.length !== 0) ? $a.get().style.color : this.getStyle('link', 'color');

        return this.app.color.normalize(color);
    },
    setTextSize: function(value) {
        this.$element.find('a').css('font-size', value);
        this.$element.css('font-size', value);
        this.$source.attr('font-size', value);
    },
    setLinkColor: function(value) {
        this.$element.find('a').css('color', value);
        this.$source.find('a').css('color', value);
    }
});
Revolvapp.add('class', 'tag.link', {
    mixins: ['tag'],
    type: 'link',
    editable: true,
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            },
            'href': {
                type: 'input',
                label: '## form.url ##'
            },
            'font-size': {
                type: 'number',
                label: '## form.text-size ##'
            },
            'text-decoration': {
                type: 'checkbox',
                text: '## form.underline ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<p>');
        this.$element.css({ 'margin': 0, 'font-family': this.getStyle('text', 'font-family') });
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'html': { target: ['link'] },
            'color': { target: ['link'], prop: this.getStyle('link', 'color') },
            'font-size': { target: ['link'], prop: this.getStyle('text', 'font-size') },
            'font-weight': { target: ['link'], prop: this.getStyle('link', 'font-weight') },
            'line-height': { target: ['link'], prop: this.getStyle('text', 'line-height') },
            'text-decoration':  { target: ['link'], prop: 'underline' },
            'align': { target: ['element'], getter: 'getAlign' },
            'margin': { target: ['element'] },
            'href': { target: ['link'] },
            'class':  { target: ['link'] },
            'font-style':  { target: ['link'] },
            'letter-spacing': { target: ['link'] },
            'text-transform': { target: ['link'] }
        };
    },
    render: function() {
        this._createElementLink();

        return this.$link;
    },

    // private
    _createElementLink: function() {
        this.$link = this.dom('<a>').html(this.params.html).addClass('rex-editable');
        this.$link.attr('target', '_blank');
        this.$link.css({
            'font-family': this.getStyle('text', 'font-family'),
            'text-decoration': 'underline'
        });

        this.$element.append(this.$link);
    }
});


Revolvapp.add('class', 'tag.heading', {
    mixins: ['tag'],
    type: 'heading',
    editable: true,
    href: false,
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            },
            'href': {
                type: 'input',
                label: '## form.url ##',
                placeholder: '## placeholders.type-url-to-add-link ##'
            },
            'level': {
                type: 'select',
                label: '## form.heading-level ##',
                options: {
                    'h1': '## headings.heading-1 ##',
                    'h2': '## headings.heading-2 ##',
                    'h3': '## headings.heading-3 ##',
                    'h4': '## headings.heading-4 ##',
                    'h5': '## headings.heading-5 ##',
                    'h6': '## headings.heading-6 ##'
                }
            },
            'font-weight': {
                type: 'checkbox',
                text: '## form.bold ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<p>').addClass(this.params.level);
        this.$element.css(this.css);
    },
    build: function() {
        this.level = (this.$source.attr('level')) ? this.$source.attr('level') : 'h2';
        this.css = this._getCss(this.level);

        this.params = {
            level: this.level,
            html: this._getSourceHtml(),
            href: this.$source.attr('href')
        };

        this.data = {
            'html': { target: ['element'] },
            'level': { target: ['element'], setter: 'setLevel', prop: this.params.level },
            'color': { target: ['element', 'link'], prop: this.getStyle('heading', 'color') },
            'font-weight': { target: ['element', 'link'], getter: 'getBold', prop: this.getStyle('heading', 'font-weight') },
            'font-size': { target: ['element', 'link'], prop: this.getHeadingStyleByLevel(this.params.level, 'font-size') },
            'line-height': { target: ['element', 'link'], prop: this.getHeadingStyleByLevel(this.params.level, 'line-height') },
            'align': { target: ['element'], getter: 'getAlign' },
            'margin': { target: ['element'] },
            'class': { target: ['element'] },
            'font-style': { target: ['element', 'link'] },
            'text-decoration': { target: ['element', 'link'] },
            'href': { target: ['link'] },
            'letter-spacing': { target: ['element', 'link'] },
            'text-transform': { target: ['element', 'link'] }
       };
    },
    render: function() {
        this._createElementLink();

        return this.$element;
    },


    setLevel: function(value) {
        var css = {
            'font-size': this.getHeadingStyleByLevel(value, 'font-size'),
            'line-height': this.getHeadingStyleByLevel(value, 'line-height')
        };

        this.$element.css(css);
        this.$link.css(css);
        this.$source.attr('level', value);
    },
    getBold: function() {
        var bold = this.$element.css('font-weight');
        return (bold === 'bold' || bold === '600' || bold === '700' || bold === '900');
    },

    // private
    _getCss: function() {
        return {
            'padding': 0,
            'margin': 0,
            'font-style': 'normal',
            'font-family': this.getStyle('heading', 'font-family')
        };
    },

    _createElementLink: function() {
        this.$link = this._createLink();
        this.$link.css({ 'text-decoration': 'none', 'display': 'block' });
        this.$link.css(this.css);

        this.$element.html('');
        this.$element.append(this.$link);

        this.$link.html(this.params.html);
        this.$link.addClass('rex-editable');
    }
});


Revolvapp.add('class', 'tag.grid', {
    mixins: ['tag'],
    type: 'grid',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    create: function() {
        this.$element = this._createTable(this.params.width);
        this.$element.addClass('grid');
        this.$row = this._createRow();
        this.$element.append(this.$row);
    },
    build: function() {
        this.params = {
            width: '100%'
        };
    },
    render: function() {
        return this.$row;
    }
});
Revolvapp.add('class', 'tag.column', {
    mixins: ['tag'],
    type: 'column',
    toolbar: {
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' }
    },
    forms: {
        settings: {
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            },
            'width': {
                type: 'input',
                width: '65px',
                label: '## form.width ##'
            }
        }
    },
    create: function() {
        this.$element = this._createCell();
        this.$element.addClass('mobile column');
    },
    build: function() {
        this.data = {
            'color': { target: false, getter: 'getElementsTextColor', setter: 'setElementsTextColor', prop: this.getStyle('text', 'color') },
            'link-color': { target: false, getter: 'getElementsLinkColor', setter: 'setElementsLinkColor', prop: this.getStyle('link', 'color') },
            'align': { target: ['element'], setter: 'setAlign' },
            'valign': { target: ['element'] },
            'width': { target: ['element'] },
            'padding': { target: ['element'] },
            'background-color': { target: ['element'] },
            'background-image': { target: ['element'] },
            'background-size': { target: ['element'] },
            'border': { target: ['element'] },
            'border-radius': { target: ['element'] },
            'class': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    },

    remove: function() {
        this.app.broadcast('component.remove', { element: this.$element });

        var spacer = this.getNext();
        if (spacer) {
            if (spacer.isType('column-spacer')) {
                spacer.remove();
            }
        }

        this.$source.remove();
        this.$element.remove();
    },
    setAlign: function(value) {
        if (value === 'left') {
            this.$element.removeAttr('align');
            this.$source.removeAttr('align');
        }
        else {
            this.$element.attr('align', value);
            this.$source.attr('align', value);
        }

        var types = ['text', 'heading', 'link', 'menu', 'social'];
        this.getElements(types).each(function($node) { $node.dataget('instance').setData({ 'align': null }); });
    }
});
Revolvapp.add('class', 'tag.column-spacer', {
    mixins: ['tag'],
    type: 'column-spacer',
    create: function() {
        this.$element = this.dom('<td>').addClass('mobile-hidden column-spacer').html('&nbsp;');
    },
    build: function() {
        this.params = {
            width: '20px'
        };

        this.data = {
            'width': { target: ['element'], getter: 'getWidth', setter: 'setWidth', prop: this.params.width }
        };
    },
    render: function() {
        return this.$element;
    },


    getWidth: function() {
        return this.$element.width();
    },
    setWidth: function(value) {
        var html = (value === 0) ? '' : '&nbsp;';

        this.$element.html(html);
        this.$element.css({ 'width': value, 'min-width': value });
        this.$source.attr('width', value);
    }
});
Revolvapp.add('class', 'tag.image', {
    mixins: ['tag'],
    type: 'image',
    href: false,
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'image': { title: '## buttons.image ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        image: {
            'src': {
                type: 'upload',
                direct: true,
                observer: 'component.checkImageChange',
                upload: {
                    success: 'image.successUpload',
                    error: 'image.error'
                }
            }
        },
        settings: {
            'width': {
                section: 'settings',
                type: 'input',
                width: '65px',
                label: '## form.width ##'
            },
            'alt': {
                section: 'settings',
                type: 'input',
                label: '## form.alt-text ##'
            },
            'href': {
                section: 'link',
                label: '## form.link ##',
                type: 'input'
            },
            'responsive': {
                section: 'settings',
                type: 'checkbox',
                text: '## form.responsive-on-mobile ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<span>');
        this.$element.css({
            'display': 'inline-block',
            'font-size': '0',
            'line-height': '0',
            'vertical-align': 'top'
        });
    },
    build: function() {
        this.params = {
            width: '100%',
            href: this.$source.attr('href'),
            placeholder: this.$source.attr('placeholder')
        };

       this.data = {
            'placeholder': { target: ['img'] },
            'width': { target: ['img'], setter: 'setWidth', getter: 'getWidth' },
            'class': { target: ['img'] },
            'src': { target: ['img'], setter: 'setImage', getter: 'getImage' },
            'alt': { target: ['img'] },
            'border-radius': { target: ['img'] },
            'border': { target: ['img'] },
            'href': { target: ['link'] },
            'responsive': { target: false, setter: 'setResponsive', getter: 'getResponsive' },
            'box-shadow': { target: ['img'] },
            'max-width': { target: ['img'] },
            'max-height': { target: ['img'] }
        };
    },
    render: function() {
        this._createElementImage();
        this._createElementLink();

        return this.$link;
    },

    isPlaceholder: function() {
        return this.params.placeholder;
    },
    getImage: function() {
        return (this.params.placeholder) ? '' : this.$img.attr('src');
    },
    getWidth: function() {
        return (this.params.placeholder) ? '' : this.$img.css('width');
    },
    getResponsive: function() {
        return (this.params.placeholder) ? false : this.$element.hasClass('mobile-image');
    },
    setResponsive: function(value) {
        if (value) {
            this.$element.addClass('mobile-image');
            this.$source.attr('responsive', true);
        }
        else {
            this.$element.removeClass('mobile-image');
            this.$source.removeAttr('responsive');
        }
    },
    setWidth: function(value) {
        if (this.params.placeholder) return;

        value = (value === null) ? '' : value;

        this.$img.attr('width', value.replace('px', ''));
        this.$img.css('width', value);
        this.$source.attr('width', value);
    },
    setImage: function(value) {
        if (value === '') return;
        if (this.params.placeholder) {
            this.$source.removeAttr('placeholder');
            this.$img = this._createImage();
            this.$link.html('');
            this.$link.append(this.$img);
            this.params.placeholder = false;
            this.$element.removeClass('rex-image-placeholder');
        }

        value = this.app.content.replaceToHttps('src', value);

        this.$img.attr('src', value);
        this.$source.attr('src', value);

        // upload image
        var stack = this.app.popup.getStack();
        if (stack && !this.params.placeholder) {
            this.$img.one('load', function() {
                var width = this.$img.css('width');
                if (stack) {
                    stack.getInput('width').val(width);
                }

                this.setWidth(width);
                this.app.control.updatePosition();
                this.app.editor.adjustHeight();
            }.bind(this));
        }
    },

    // private
    _createElementImage: function() {
        if (this.params.placeholder) {
            this.$img = this.dom(this.opts.placeholders.image);
            this.$element.addClass('rex-image-placeholder');
        }
        else {
            this.$source.removeAttr('placeholder');
            this.$img = this._createImage();
        }
    },
    _createElementLink: function() {
        this.$link = this._createLink();
        this.$link.css({
            'text-decoration': 'none',
            'cursor': 'pointer',
            'line-height': '100%',
            'font-size': '0px',
            'display': 'block'
        });

        this.$link.append(this.$img);
        this.$element.append(this.$link);
    }
});
Revolvapp.add('class', 'tag.menu', {
    mixins: ['tag'],
    type: 'menu',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'items': { title: '## buttons.items ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        item: {
            'html': {
                type: 'input',
                label: '## form.name ##'
            },
            'href': {
                type: 'input',
                label: '## form.url ##'
            },
            'text-decoration': {
                type: 'checkbox',
                text: '## form.underline ##'
            }
        },
        settings: {
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            },
            'font-size': {
                type: 'number',
                label: '## form.text-size ##'
            },
            'html': {
                type: 'input',
                label: '## form.spacer-content ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<div>').addClass('menu');
    },
    build: function() {
        this.data = {
            'color': { target: false, getter: 'getTextColor', setter: 'setTextColor', prop: this.getStyle('text', 'color') },
            'font-size': { target: false, getter: 'getTextSize', setter: 'setTextSize', prop: this.getStyle('text', 'font-size') },
            'align': { target: ['element'], getter: 'getAlign' },
            'margin': { target: ['element'] },
            'class': { target: ['element'] },
            'html': { target: false, getter: 'getSpacerContent', setter: 'setSpacerContent' }
        };
    },
    render: function() {
        return this.$element;
    },


    getSpacers: function() {
        return this.getElements(['menu-spacer']);
    },
    getItems: function() {
        return this.getElements(['menu-item']);
    },
    getItemsAndSpacers: function() {
        return this.getElements(['menu-item', 'menu-spacer']);
    },
    getItemInstance: function() {
        return this.getItems().first().dataget('instance');
    },
    getSpacerInstance: function() {
        return this.getSpacers().first().dataget('instance');
    },

    // getters
    getTextSize: function() {
        var instance = this.getItemInstance();

        return (instance) ? instance.getData('font-size') : this.getStyle('text', 'font-size');
    },
    getTextColor: function() {
        var instance = this.getItemInstance();

        return (instance) ? instance.getData('color') : this.getStyle('text', 'color');
    },
    getSpacerContent: function() {
        var instance = this.getSpacerInstance();

        return (instance) ? instance.getData('html') : '';
    },
    setTextSize: function(value) {
        this.getItems().each(function($node) { $node.dataget('instance').setData({ 'font-size': value }); });
    },
    setTextColor: function(value) {
        this.getItemsAndSpacers().each(function($node) { $node.dataget('instance').setData({ 'color': value }); });
    },
    setSpacerContent: function(value) {
        this.getSpacers().each(function($node) { $node.dataget('instance').setData({ 'html': value }); });
    }
});
Revolvapp.add('class', 'tag.menu-item', {
    mixins: ['tag'],
    type: 'menu-item',
    create: function() {
        this.$element = this.dom('<a>');
        this.$element.html(this.params.html);
        this.$element.css('font-family', this.getStyle('text', 'font-family'));
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml(),
            href: this.$source.attr('href')
        };

        this.data = {
            'color': { target: ['element'], prop: this.getStyle('text', 'color') },
            'font-size': { target: ['element'], prop: this.getStyle('text', 'font-size') },
            'text-decoration': { target: ['element'], prop: ((this.params.href) ? 'underline' : 'none') },
            'html': { target: ['element'] },
            'href': { target: ['element'] },
            'class': { target: ['element'] },
            'font-weight': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    },


    removeItem: function() {
        this.removeSpacer();
        this.remove();
    },
    removeSpacer: function() {
        this.removeNextSpacer();
        var $next = this.$element.nextElement();
        if ($next.length === 0) {
            this.removePrevSpacer();
        }
    },
    removePrevSpacer: function() {
        var $prev = this.$element.prevElement();
        if ($prev.attr('data-' + this.prefix + '-type') === 'menu-spacer') {
            var spacerInstance = $prev.dataget('instance');
            spacerInstance.remove();
        }
    },
    removeNextSpacer: function() {
        var $next = this.$element.nextElement();
        if ($next.attr('data-' + this.prefix + '-type') === 'menu-spacer') {
            var spacerInstance = $next.dataget('instance');
            spacerInstance.remove();
        }
    }
});


Revolvapp.add('class', 'tag.menu-spacer', {
    mixins: ['tag'],
    type: 'menu-spacer',
    create: function() {
        this.$element = this.dom('<span>').html(this.params.html);
        this.$element.css({
            'display': 'inline-block',
            'line-height': 0,
            'font-family': this.getStyle('text', 'font-family')
        });
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'font-size': { target: ['element'], prop: this.getStyle('text', 'font-size') },
            'class': { target: ['element'], prop: this.getStyle('text', 'color') },
            'html': { target: ['element'] },
            'color': { target: ['element'] },
            'font-weight': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.social', {
    mixins: ['tag'],
    type: 'social',
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'items': { title: '## buttons.items ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        item: {
            'src': {
                type: 'upload',
                direct: true,
                observer: 'component.checkImageChange',
                upload: {
                    cover: false,
                    success: 'image.successSocialUpload',
                    error: 'image.error'
                }
            },
            'width': {
                type: 'input',
                label: '## form.image-width ##',
                width: '75px'
            },
            'href': {
                type: 'input',
                label: '## form.link ##'
            },
            'alt': {
                type: 'input',
                label: '## form.alt-text ##'
            }
        },
        settings: {
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            }
        }
    },
    create: function() {
        this.$element = this.dom('<div>');
        this.$element.addClass('social');
    },
    build: function() {
        this.data = {
            'align': { target: ['element'], getter: 'getAlign' },
            'margin':  { target: ['element'] },
            'class':  { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    },


    getItems: function() {
        return this.getElements(['social-item']);
    },
    getSpacers: function() {
        return this.getElements(['social-spacer']);
    }
});
Revolvapp.add('class', 'tag.social-item', {
    mixins: ['tag'],
    type: 'social-item',
    create: function() {
        this.$element = this.dom('<a>');
    },
    build: function() {
        this.params = {
            href: this.$source.attr('href'),
            src: this.$source.attr('src'),
            placeholder: this.$source.attr('placeholder')
        };

        this.data = {
            'placeholder': { target: ['element'] },
            'href': { target: ['element'] },
            'class': { target: ['element'] },
            'width': { target: ['img'], setter: 'setWidth', getter: 'getWidth' },
            'alt': { target: ['img'] },
            'src': { target: ['img'], setter: 'setImage', getter: 'getImage' }
        };
    },
    render: function() {
        this._createElementImage();

        return this.$element;
    },



    isPlaceholder: function() {
        return this.params.placeholder;
    },
    removeItem: function() {
        this.removeSpacer();
        this.remove();
    },
    removeSpacer: function() {
        this.removeNextSpacer();
        var $next = this.$element.nextElement();
        if ($next.length === 0) {
            this.removePrevSpacer();
        }
    },
    removePrevSpacer: function() {
        var $prev = this.$element.prevElement();
        if ($prev.attr('data-' + this.prefix + '-type') === 'social-spacer') {
            var spacerInstance = $prev.dataget('instance');
            spacerInstance.remove();
        }
    },
    removeNextSpacer: function() {
        var $next = this.$element.nextElement();
        if ($next.attr('data-' + this.prefix + '-type') === 'social-spacer') {
            var spacerInstance = $next.dataget('instance');
            spacerInstance.remove();
        }
    },
    getWidth: function() {
        return (this.params.placeholder) ? '' : this.$img.css('width');
    },
    getImage: function() {
        return (this.params.placeholder) ? '' : this.$img.attr('src');
    },
    setImage: function(value) {
        if (value === '') return;
        if (this.params.placeholder) {
            this.$source.removeAttr('placeholder');
            this.$img = this._createImage();
            this.$element.html('');
            this.$element.append(this.$img);
            this.params.placeholder = false;
            this.$element.removeClass('rex-social-placeholder');
        }

        value = this.app.content.replaceToHttps('src', value);

        this.$img.attr('src', value);
        this.$source.attr('src', value);
    },
    setWidth: function(value) {
        if (this.params.placeholder) return;

        value = (value === null) ? '' : value;

        this.$img.attr('width', value);
        this.$img.css('width', value);
        this.$source.attr('width', value);
    },

    // private
    _createElementImage: function() {
        if (this.params.placeholder) {
            this.$img = this.dom(this.opts.placeholders.social);
            this.$element.addClass('rex-social-placeholder');
        }
        else {
            this.$source.removeAttr('placeholder');
            this.$img = this._createImage();
        }

        this.$element.append(this.$img);
    }
});


Revolvapp.add('class', 'tag.social-spacer', {
    mixins: ['tag'],
    type: 'social-spacer',
    create: function() {
        this.$element = this.dom('<span>').html(this.params.html);
        this.$element.css({
            'display': 'inline-block',
            'line-height': 0,
            'font-family': this.getStyle('text', 'font-family')
        });
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'font-size': { target: ['element'], prop: this.getStyle('text', 'font-size') },
            'class': { target: ['element'], prop: this.getStyle('text', 'color') },
            'html': { target: ['element'] },
            'color': { target: ['element'] },
            'font-weight': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.button', {
    mixins: ['tag'],
    type: 'button',
    editable: true,
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'border': { title: '## buttons.border ##',  command: 'component.popup' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            },
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            },
            'href': {
                type: 'input',
                label: '## form.url ##'
            },
            'font-size': {
                type: 'number',
                label: '## form.text-size ##'
            }
        }
    },
    create: function() {
        this.$element = this._createTableContainer(this.params.width);
        this.$cell.attr({ 'valign': 'top', 'align': 'center' });
        this.$cell.css({
            'vertical-align': 'top',
            'text-align': 'center',
            'font-family': this.getStyle('text', 'font-family')
        });
    },
    build: function() {
        this.params = {
            width: 'auto',
            html: this._getSourceHtml()
        };

        var border = this.$source.attr('border');
        var bgcolor = this.$source.attr('background-color');
        if (!border) {
            border = (bgcolor) ? bgcolor : this.getStyle('button', 'background-color');
        }

        this.data = {
            'html': { target: ['link'] },
            'font-size': { target: ['element', 'link'], prop: this.getStyle('button', 'font-size') },
            'font-weight': { target: ['element', 'link'], prop: this.getStyle('button', 'font-weight') },
            'background-color': { target: ['element', 'link'], prop: this.getStyle('button', 'background-color') },
            'color': { target: ['element', 'link'], prop: this.getStyle('button', 'color') },
            'border-radius': { target: ['element', 'link', 'cell'], prop: this.getStyle('button', 'border-radius') },
            'border': { target: ['link'], setter: 'setBorder', prop: '1px solid ' + border },
            'padding': { target: ['link'], prop: this.getStyle('button', 'padding') },
            'margin': { target: ['element'] },
            'font-style': { target: ['element', 'link'] },
            'class': { target: ['link'] },
            'href': { target: ['link'] },
            'letter-spacing': { target: ['link'] },
            'text-transform': { target: ['link'] }
        };

    },
    render: function() {
        this._createElementLink();

        return this.$link;
    },


    setBorder: function(value) {
        var arr = value.split(' ');
        this.$link.css('border', value);
        this.$cell.attr('bgcolor', arr[2]);
        this.$source.attr('border', value);
    },

    // private
    _createElementLink: function() {
        this.$link = this.dom('<a>').html(this.params.html).addClass('rex-editable');
        this.$link.attr('target', '_blank');
        this.$link.css({
            'display': 'inline-block',
            'box-sizing': 'border-box',
            'cursor': 'pointer',
            'text-decoration': 'none',
            'margin': 0,
            'font-family': this.getStyle('text', 'font-family')
        });

        this.$cell.append(this.$link);
    }
});
Revolvapp.add('class', 'tag.table', {
    mixins: ['tag'],
    type: 'table',
    create: function() {
        this.$element = this._createTable(this.params.width);
        this.$element.addClass('table');
    },
    build: function() {
        this.params = {
            width: '100%'
        };

        this.data = {
            'class': { target: ['element'] },
            'padding': { target: ['element'] },
            'border': { target: ['element'] },
            'background-color': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.table-head', {
    mixins: ['tag'],
    type: 'table-head',
    create: function() {
        this.$element = this.dom('<thead>');
    },
    build: function() {
        this.data = {
            'class': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.table-body', {
    mixins: ['tag'],
    type: 'table-body',
    create: function() {
        this.$element = this.dom('<tbody>');
    },
    build: function() {
        this.data = {
            'class': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.table-row', {
    mixins: ['tag'],
    type: 'table-row',
    create: function() {
        this.$element = this.dom('<tr>');
    },
    build: function() {
        this.data = {
            'class': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.table-cell', {
    mixins: ['tag'],
    type: 'table-cell',
    editable: true,
    toolbar: {
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'link': { title: '## buttons.link ##',  command: 'link.popup' },
        'background': { title: '## buttons.background ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    forms: {
        settings: {
            'width': {
                type: 'input',
                label: '## form.width ##'
            },
            'padding': {
                type: 'input',
                label: '## form.padding ##'
            },
            'font-size': {
                type: 'number',
                label: '## form.text-size ##'
            }
        }
    },
    create: function() {
        this.$element = this._createCell();
        this.$element.html(this.params.html);
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'width': { target: ['element'] },
            'align': { target: ['element'] },
            'rowspan': { target: ['element'] },
            'colspan': { target: ['element'] },
            'class': { target: ['element'] },
            'padding': { target: ['element'], prop: this.getStyle('table', 'padding') },
            'border': { target: ['element'] },
            'color': { target: ['element'] },
            'font-size': { target: ['element'], setter: 'setTextSize', prop: this.getStyle('text', 'font-size') },
            'line-height': { target: ['element'], prop: this.getStyle('text', 'line-height') },
            'background-color': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    },

    setTextSize: function(value) {
        this.$element.find('a').css('font-size', value);
        this.$element.css('font-size', value);
        this.$source.attr('font-size', value);
    }
});
Revolvapp.add('class', 'tag.code', {
    mixins: ['tag'],
    type: 'code',
    create: function() {
        this.$element = this.dom('<pre>').html('');
        this.$element.css({
            'font-family': this.getStyle('code', 'font-family'),
            'margin': 0,
            'overflow': 'auto',
            'white-space': 'pre'
        });
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'font-size': { target: ['element'], prop: this.getStyle('code', 'font-size') },
            'line-height': { target: ['element'], prop: this.getStyle('code', 'line-height') },
            'color': { target: ['element'], prop: this.getStyle('code', 'color') },
            'padding': { target: ['element'], prop: this.getStyle('code', 'padding') },
            'background-color': { target: ['element'], prop: this.getStyle('code', 'background-color') },
            'class': { target: ['element'] },
            'border': { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('class', 'tag.list', {
    mixins: ['tag'],
    type: 'list',
    editable: true,
    toolbar: {
        'add': { title: '## buttons.add ##',  command: 'component.popup' },
        'alignment': { title: '## buttons.alignment ##',  command: 'component.popup' },
        'link': { title: '## buttons.link ##',  command: 'link.popup' },
        'text-color': { title: '## buttons.text-color ##', command: 'component.popup', color: true, observer: 'component.observe' },
        'tune': { title: '## buttons.settings ##',  command: 'component.popup' }
    },
    control: {
        trash: { command: 'component.remove' },
        duplicate: { command: 'component.duplicate' }
    },
    forms: {
        settings: {
            'type': {
                type: 'select',
                label: '## form.list-type ##',
                options: {
                    'unordered': '## lists.unordered ##',
                    'ordered': '## lists.ordered ##'
                }
            },
            'margin': {
                type: 'input',
                label: '## form.margin ##'
            },
            'font-size': {
                type: 'number',
                label: '## form.text-size ##'
            }
        }
    },
    create: function() {
        var type = (this.params.type) ? this.params.type : 'unordered';
        type = (type === 'unordered') ? 'ul' : 'ol';

        var align = this.$source.attr('type') || this.opts.editor.align;

        this.$element = this.dom('<' + type + '>');
        this.$element.css({ 'margin': 0, 'padding': 0, 'font-family': this.getStyle('text', 'font-family'), 'text-align': align });
    },
    build: function() {
        this.params = {
            type: this.$source.attr('type')
        };

        var align = this.$source.attr('type') || this.opts.editor.align;

        this.data = {
            'type': { target: ['element'], setter: 'setListType', getter: 'getListType' },
            'margin':  { target: ['element'] },
            'color': { target: ['element'], prop: this.getStyle('text', 'color'), setter: 'setTextColor' },
            'align': { target: ['element'], getter: 'getAlign', setter: 'setAlign', prop: align },
            'font-size': { target: ['element'], setter: 'setTextSize', prop: this.getStyle('text', 'font-size') },
            'font-weight': { target: ['element'], prop: this.getStyle('text', 'font-weight') },
            'line-height': { target: ['element'], prop: this.getStyle('text', 'line-height') },
            'class':  { target: ['element'] }
        };
    },
    render: function() {
        return this.$element;
    },
    getListType: function() {
        var tag = this.getTag();

        return (tag === 'ul') ? 'unordered' : 'ordered';
    },
    setListType: function(value) {
        var tag = this.getTag();
        var type = (value === 'unordered') ? 'ul' : 'ol';

        if (type !== tag) {
            this.$element = this.app.element.replaceToTag(this.$element, type, true);
            this.$element.dataset('instance', this);
            this.app.editor.rebuild();

            this.$source.attr('type', value);
        }
    },
    setAlign: function(value) {
        this.$element.attr('align', value)
        this.$element.css({ 'text-align': value });
        this.$element.find('li').css({ 'text-align': value });
        this.$source.attr('align', value);
    },
    setTextColor: function(value) {
        this.$element.find('li').css('color', value);
        this.$source.attr('color', value);
    },
    setTextSize: function(value) {
        this.$element.find('a, li').css('font-size', value);
        this.$element.css('font-size', value);
        this.$source.attr('font-size', value);
    }
});


Revolvapp.add('class', 'tag.list-item', {
    mixins: ['tag'],
    type: 'list-item',
    create: function() {

        var $parent = this.$source.parent();
        var align = $parent.attr('align') || this.opts.editor.align;

        this.$element = this.dom('<li>');
        this.$element.css({
            'font-family': $parent.attr('font-family') || this.getStyle('text', 'font-family'),
            'font-size': $parent.attr('font-size') || this.getStyle('text', 'font-size'),
            'font-weight': $parent.attr('font-weight') || this.getStyle('text', 'font-weight'),
            'line-height': $parent.attr('line-height') || this.getStyle('text', 'line-height'),
            'color': $parent.attr('color') || this.getStyle('text', 'color'),
            'margin': 0,
            'margin-left': '24px',
            'text-align': align
        });
        this.$element.html(this.params.html);
    },
    build: function() {
        this.params = {
            html: this._getSourceHtml()
        };

        this.data = {
            'class':  { target: ['element'] }
        };
    },
    render: function() {
        this._parseHtmlLinks(this.$source, this.$element, this);

        return this.$element;
    }
});


Revolvapp.add('class', 'tag.var', {
    mixins: ['tag'],
    type: 'var',
    create: function() {
        this.$element = this.dom('<re-var>').attr('data-type', this.$source.attr('data-type'));
        this.$element.css('display', 'none');
        this.$element.html(this.$source.text());
    },
    render: function() {
        return this.$element;
    }
});
Revolvapp.add('block', 'block.text', {
    mixins: ['block'],
    type: 'text',
    section: 'one',
    priority: 10,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 20px 20px' });

        // elements
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        this.block.add(text);
    }
});
Revolvapp.add('block', 'block.heading', {
    mixins: ['block'],
    type: 'heading',
    section: 'one',
    priority: 20,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 5px 20px' });

        // elements
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading') });

        // add
        this.block.add(heading);
    }
});
Revolvapp.add('block', 'block.heading-text', {
    mixins: ['block'],
    type: 'heading-text',
    section: 'one',
    priority: 30,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 20px 20px' });

        // elements
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), margin: '0 0 5px 0' });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        this.block.add(heading);
        this.block.add(text);
    }
});
Revolvapp.add('block', 'block.image', {
    mixins: ['block'],
    type: 'image',
    section: 'one',
    priority: 40,
    build: function() {

        // block
        this.block = this.app.create('tag.block');

        // elements
        var image = this.app.create('tag.image', { placeholder: true });

        // add
        this.block.add(image);
    }
});
Revolvapp.add('block', 'block.image-text', {
    mixins: ['block'],
    type: 'image-text',
    section: 'one',
    priority: 50,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 20px 20px' });

        // elements
        var image = this.app.create('tag.image', { placeholder: true });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem'), margin: '10px 0 0 0' });

        // add
        this.block.add(image);
        this.block.add(text);
    }
});
Revolvapp.add('block', 'block.image-heading-text', {
    mixins: ['block'],
    type: 'image-heading-text',
    section: 'one',
    priority: 60,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 20px 20px' });

        // elements
        var image = this.app.create('tag.image', { placeholder: true });
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), margin: '10px 0 5px 0' });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        this.block.add(image);
        this.block.add(heading);
        this.block.add(text);
    }
});
Revolvapp.add('block', 'block.button', {
    mixins: ['block'],
    type: 'button',
    section: 'one',
    priority: 70,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px' });

        // elements
        var button = this.app.create('tag.button', { html: this.lang.get('placeholders.button') });

        // add
        this.block.add(button);
    }
});
Revolvapp.add('block', 'block.link', {
    mixins: ['block'],
    type: 'link',
    section: 'one',
    priority: 80,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px' });

        // elements
        var link = this.app.create('tag.link', { html: this.lang.get('placeholders.link') });

        // add
        this.block.add(link);
    }
});
Revolvapp.add('block', 'block.divider', {
    mixins: ['block'],
    type: 'divider',
    section: 'one',
    priority: 90,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 0' });

        // elements
        var divider = this.app.create('tag.divider');

        // add
        this.block.add(divider);
    }
});
Revolvapp.add('block', 'block.spacer', {
    mixins: ['block'],
    type: 'spacer',
    section: 'one',
    priority: 100,
    build: function() {

        // block
        this.block = this.app.create('tag.block');

        // elements
        var spacer = this.app.create('tag.spacer');

        // add
        this.block.add(spacer);
    }
});
Revolvapp.add('block', 'block.menu', {
    mixins: ['block'],
    type: 'menu',
    section: 'one',
    priority: 110,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { align: 'center', padding: '10px 20px' });

        // elements
        var menu = this.app.create('tag.menu');
        var item1 = this.app.create('tag.menu-item', { href: 'https://example.com', html: this.lang.get('placeholders.item') + ' 1' });
        var item2 = this.app.create('tag.menu-item', { href: 'https://example.com', html: this.lang.get('placeholders.item') + ' 2' });
        var spacer = this.app.create('tag.menu-spacer', { html: '&nbsp;&nbsp;&nbsp;' });

        // add
        menu.add(item1);
        menu.add(spacer);
        menu.add(item2);

        this.block.add(menu);
    }
});
Revolvapp.add('block', 'block.social', {
    mixins: ['block'],
    type: 'social',
    section: 'one',
    priority: 120,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { align: 'center', padding: '10px 20px' });

        // elements
        var social = this.app.create('tag.social');
        var item1 = this.app.create('tag.social-item', { placeholder: true, href: 'https://facebook.com', alt: 'Facebook' });
        var item2 = this.app.create('tag.social-item', { placeholder: true, href: 'https://twitter.com', alt: 'Twitter' });
        var spacer = this.app.create('tag.social-spacer', { html: '&nbsp;&nbsp;&nbsp;' });

        // add
        social.add(item1);
        social.add(spacer);
        social.add(item2);

        this.block.add(social);
    }
});
Revolvapp.add('block', 'block.list', {
    mixins: ['block'],
    type: 'list',
    section: 'one',
    priority: 130,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 20px 20px' });

        // elements
        var list = this.app.create('tag.list');
        var item = this.app.create('tag.list-item');

        // add item
        list.add(item);

        // add list
        this.block.add(list);
    }
});
Revolvapp.add('block', 'block.two-text', {
    mixins: ['block'],
    type: 'two-text',
    section: 'two',
    priority: 10,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(text1);
        col2.add(text2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.two-headings-text', {
    mixins: ['block'],
    type: 'two-headings-text',
    section: 'two',
    priority: 50,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var heading1 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), margin: '0 0 5px 0' });
        var heading2 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), margin: '0 0 5px 0' });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(heading1);
        col1.add(text1);
        col2.add(heading2);
        col2.add(text2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.two-images', {
    mixins: ['block'],
    type: 'two-images',
    section: 'two',
    priority: 20,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image1 = this.app.create('tag.image', { placeholder: true });
        var image2 = this.app.create('tag.image', { placeholder: true });

        // add
        col1.add(image1);
        col2.add(image2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.two-images-text', {
    mixins: ['block'],
    type: 'two-images-text',
    section: 'two',
    priority: 60,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image1 = this.app.create('tag.image', { placeholder: true });
        var image2 = this.app.create('tag.image', { placeholder: true });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem'), margin: '10px 0 0 0' });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem'), margin: '10px 0 0 0' });

        // add
        col1.add(image1);
        col1.add(text1);
        col2.add(image2);
        col2.add(text2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.two-images-headings-text', {
    mixins: ['block'],
    type: 'two-images-headings-text',
    section: 'two',
    priority: 70,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image1 = this.app.create('tag.image', { placeholder: true });
        var image2 = this.app.create('tag.image', { placeholder: true });
        var heading1 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '10px 0 5px 0' });
        var heading2 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '10px 0 5px 0' });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });


        // add
        col1.add(image1);
        col1.add(heading1);
        col1.add(text1);
        col2.add(image2);
        col2.add(heading2);
        col2.add(text2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.two-buttons', {
    mixins: ['block'],
    type: 'two-buttons',
    section: 'two',
    priority: 30,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%', align: 'right' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var button1 = this.app.create('tag.button', { html: this.lang.get('placeholders.button') });
        var button2 = this.app.create('tag.button', { html: this.lang.get('placeholders.button') });

        // add
        col1.add(button1);
        col2.add(button2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});
Revolvapp.add('block', 'block.two-links', {
    mixins: ['block'],
    type: 'two-links',
    section: 'two',
    priority: 40,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', align: 'right', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var link1 = this.app.create('tag.link', { html: this.lang.get('placeholders.link'), align:'right' });
        var link2 = this.app.create('tag.link', { html: this.lang.get('placeholders.link') });

        // add
        col1.add(link1);
        col2.add(link2);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});
Revolvapp.add('block', 'block.three-text', {
    mixins: ['block'],
    type: 'three-text',
    section: 'three',
    priority: 10,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col3 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var spacer1 = this.app.create('tag.column-spacer', { width: '20px' });
        var spacer2 = this.app.create('tag.column-spacer', { width: '20px' });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });
        var text3 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });

        // add
        col1.add(text1);
        col2.add(text2);
        col3.add(text3);

        grid.add(col1);
        grid.add(spacer1);
        grid.add(col2);
        grid.add(spacer2);
        grid.add(col3);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.three-headings-text', {
    mixins: ['block'],
    type: 'three-headings-text',
    section: 'three',
    priority: 30,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col3 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var spacer1 = this.app.create('tag.column-spacer', { width: '20px' });
        var spacer2 = this.app.create('tag.column-spacer', { width: '20px' });
        var heading1 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '0 0 5px 0' });
        var heading2 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '0 0 5px 0' });
        var heading3 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '0 0 5px 0' });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });
        var text3 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });

        // add
        col1.add(heading1);
        col1.add(text1);
        col2.add(heading2);
        col2.add(text2);
        col3.add(heading3);
        col3.add(text3);

        grid.add(col1);
        grid.add(spacer1);
        grid.add(col2);
        grid.add(spacer2);
        grid.add(col3);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.three-images', {
    mixins: ['block'],
    type: 'three-images',
    section: 'three',
    priority: 20,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col3 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var spacer1 = this.app.create('tag.column-spacer', { width: '20px' });
        var spacer2 = this.app.create('tag.column-spacer', { width: '20px' });
        var image1 = this.app.create('tag.image', { placeholder: true });
        var image2 = this.app.create('tag.image', { placeholder: true });
        var image3 = this.app.create('tag.image', { placeholder: true });

        // add
        col1.add(image1);
        col2.add(image2);
        col3.add(image3);

        grid.add(col1);
        grid.add(spacer1);
        grid.add(col2);
        grid.add(spacer2);
        grid.add(col3);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.three-images-text', {
    mixins: ['block'],
    type: 'three-images-text',
    section: 'three',
    priority: 40,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col3 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var spacer1 = this.app.create('tag.column-spacer', { width: '20px' });
        var spacer2 = this.app.create('tag.column-spacer', { width: '20px' });
        var image1 = this.app.create('tag.image', { placeholder: true });
        var image2 = this.app.create('tag.image', { placeholder: true });
        var image3 = this.app.create('tag.image', { placeholder: true });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short'), margin: '10px 0 0 0' });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short'), margin: '10px 0 0 0' });
        var text3 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short'), margin: '10px 0 0 0' });

        // add
        col1.add(image1);
        col1.add(text1);
        col2.add(image2);
        col2.add(text2);
        col3.add(image3);
        col3.add(text3);

        grid.add(col1);
        grid.add(spacer1);
        grid.add(col2);
        grid.add(spacer2);
        grid.add(col3);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.three-images-headings-text', {
    mixins: ['block'],
    type: 'three-images-headings-text',
    section: 'three',
    priority: 50,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var col3 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '33%' });
        var spacer1 = this.app.create('tag.column-spacer', { width: '20px' });
        var spacer2 = this.app.create('tag.column-spacer', { width: '20px' });
        var image1 = this.app.create('tag.image', { placeholder: true });
        var image2 = this.app.create('tag.image', { placeholder: true });
        var image3 = this.app.create('tag.image', { placeholder: true });
        var heading1 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '10px 0 5px 0' });
        var heading2 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '10px 0 5px 0' });
        var heading3 = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '10px 0 5px 0' });
        var text1 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });
        var text2 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });
        var text3 = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem-short') });

        // add
        col1.add(image1);
        col1.add(heading1);
        col1.add(text1);
        col2.add(image2);
        col2.add(heading2);
        col2.add(text2);
        col3.add(image3);
        col3.add(heading3);
        col3.add(text3);

        grid.add(col1);
        grid.add(spacer1);
        grid.add(col2);
        grid.add(spacer2);
        grid.add(col3);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.misc-heading-text', {
    mixins: ['block'],
    type: 'misc-heading-text',
    section: 'misc',
    priority: 50,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading') });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(heading);
        col2.add(text);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.misc-text-heading', {
    mixins: ['block'],
    type: 'misc-text-heading',
    section: 'misc',
    priority: 60,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading') });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(text);
        col2.add(heading);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

Revolvapp.add('block', 'block.misc-image-text', {
    mixins: ['block'],
    type: 'misc-image-text',
    section: 'misc',
    priority: 10,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image = this.app.create('tag.image', { placeholder: true });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(image);
        col2.add(text);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});
Revolvapp.add('block', 'block.misc-text-image', {
    mixins: ['block'],
    type: 'misc-text-image',
    section: 'misc',
    priority: 20,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '50%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image = this.app.create('tag.image', { placeholder: true });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(text);
        col2.add(image);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});
Revolvapp.add('block', 'block.misc-image-heading-text', {
    mixins: ['block'],
    type: 'misc-image-heading-text',
    section: 'misc',
    priority: 30,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '40%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '60%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image = this.app.create('tag.image', { placeholder: true });
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '0 0 5px 0' });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(image);
        col2.add(heading);
        col2.add(text);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});
Revolvapp.add('block', 'block.misc-heading-text-image', {
    mixins: ['block'],
    type: 'misc-heading-text-image',
    section: 'misc',
    priority: 40,
    build: function() {

        // block
        this.block = this.app.create('tag.block', { padding: '10px 20px 0 20px' });

        // elements
        var grid = this.app.create('tag.grid');
        var col1 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '60%' });
        var col2 = this.app.create('tag.column', { padding: '0 0 20px 0', width: '40%' });
        var spacer = this.app.create('tag.column-spacer', { width: '20px' });
        var image = this.app.create('tag.image', { placeholder: true });
        var heading = this.app.create('tag.heading', { html: this.lang.get('placeholders.lorem-heading'), level: 'h3', margin: '0 0 5px 0' });
        var text = this.app.create('tag.text', { html: this.lang.get('placeholders.lorem') });

        // add
        col1.add(heading);
        col1.add(text);
        col2.add(image);

        grid.add(col1);
        grid.add(spacer);
        grid.add(col2);

        this.block.add(grid);
    }
});

    window.$RE = window.Revolvapp = Revolvapp;

    // Data attribute load
    window.addEventListener('load', function() {
        Revolvapp('[data-revolvapp]');
    });

    // Export for webpack
    if (typeof module === 'object' && module.exports) {
        module.exports = Revolvapp;
        module.exports.Revolvapp = Revolvapp;
    }
}());