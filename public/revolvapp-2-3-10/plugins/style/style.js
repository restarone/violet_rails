(function() {
    Revolvapp.add('plugin', 'style', {
        translations: {
            en: {
                "style": {
                    "style": "Style",
                    "remove-style": "Remove Style"
                }
            }
        },
        defaults: {
            icon: '<svg height="16" viewBox="0 0 16 16" width="16" xmlns="http://www.w3.org/2000/svg"><path d="m15 1c-3.5955345 2.88454776-5.25146525 9.6241453-7.87485347 9.6241453h-2.6253419l-2.62495116 4.3758547h-.87485347c1.75009768-5.25102559 6.33028189-14 14-14z"/></svg>',
            styles: false
        },
        popups: {
            base: {
                builder: 'style.buildItems'
            }
        },
        init: function() {},
        start: function() {
            var keys = Object.keys(this.opts.style.styles);
            if (keys.length === 0) {
                return;
            }

            this.app.toolbar.add('style', {
                title: '## style.style ##',
                icon: this.opts.style.icon,
                components: keys,
                command: 'style.popup'
            });
        },
        popup: function(params, button) {
            this.app.popup.create('style', this.popups.base);
            this.app.popup.open({ button: button });
        },
        set: function(params, button, name) {
            this.app.popup.close();

            var params = button.getParams();
            var styles = this.opts.style.styles;
            var instance = this.app.component.get();
            var type = instance.getType();
            var stylename = instance.getSourceStyle();
            var $source = instance.getSource();

            if (typeof styles[type] === 'undefined') {
                return;
            }

            if (stylename === name) {
                $source.removeAttr('stylename style');
                instance.removeStyle(params);
            }
            else {
                if (stylename) {
                    instance.removeStyle(styles[type][stylename].css);
                }

                instance.setStyle(params);
                $source.attr('stylename', name);
                $source.attr('style', this._objectToCss(params));
            }

            this.app.toolbar.build();
        },
        buildItems: function() {
            var items = {};
            var instance = this.app.component.get();
            var type = instance.getType();
            var stylename = instance.getSourceStyle();
            var styles = this.opts.style.styles;
            if (typeof styles[type] === 'undefined') {
                return;
            }

            for (var key in styles[type]) {
                items[key] = {
                    title: styles[type][key].title,
                    active: (stylename === key),
                    params: styles[type][key].css,
                    command: 'style.set'
                };
            }

            return items;
        },

        // private
        _objectToCss: function(obj) {
            var keys = Object.keys(obj);
            var str = '';

            for (var i = 0; i < keys.length; i++) {
                var key = keys[i];
                str += key + ':' + obj[key] + ';';
            }

            return str;
        }
    });
})(Revolvapp);