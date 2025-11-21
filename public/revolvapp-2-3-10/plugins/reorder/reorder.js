(function() {
    Revolvapp.add('plugin', 'reorder', {
        defaults: {
            icon: '<svg height="16" viewBox="0 0 16 16" width="16" xmlns="http://www.w3.org/2000/svg"><path d="m3 5h10c.5522847 0 1 .44771525 1 1s-.4477153 1-1 1h-10c-.55228475 0-1-.44771525-1-1s.44771525-1 1-1zm0 4h10c.5522847 0 1 .44771525 1 1 0 .5522847-.4477153 1-1 1h-10c-.55228475 0-1-.4477153-1-1 0-.55228475.44771525-1 1-1z"/></svg>'
        },
        subscribe: {
            'component.set': function() {
                this._observe();
            }
        },
        init: function() {},
        start: function() {
            this.app.control.add('reorder', {
                icon: this.opts.reorder.icon,
                position: 'first',
                except: ['header', 'main', 'footer', 'column', 'table-row', 'table-cell']
            });
        },
        stop: function() {
            this._stopEvents();
        },

        // private
        _observe: function() {
            this.$btn = this.app.control.get('reorder');
            if (this.$btn.length === 0) return;
            this.$btn.addClass(this.prefix + '-handle');

            this._sortable();
        },
        _sortable: function() {
            this._buildInstance(this.app.component.get());
            this.coreParent = this.parent;

            this.$win = this.app.editor.getWin();
            this.tolerance = this.$btn.width();
            this.$clickItem = null;
            this.$dragItem  = null;
            this.oldY = 0;
            this.dragging = false;

            this.$btn.on('mousedown.' + this.prefix + '-reorder touchstart.' + this.prefix + '-reorder', this._press.bind(this));
        },
        _press: function(e) {
            var $target = this.dom(e.target).closest('.rex-button');
            if (e && e.target && $target.hasClass('rex-handle')) {
                e.preventDefault();

                this.$win.on('mouseup.' + this.prefix + '-reorder touchend.' + this.prefix + '-reorder', this._release.bind(this));
                this.$win.on('mousemove.' + this.prefix + '-reorder touchmove.' + this.prefix + '-reorder', this._move.bind(this));

                var item = this.instance.getElement().get();
                this.app.component.unset();

                this.dragging = true;
                this.$dragItem = this._makeDragItem(item, e.target);
            }
        },
        _release: function(e) {
            this._stopEvents();

            if (this.coreParent.isEmpty()) {
                this.coreParent.remove();
            }

            this.app.observer.trigger = true;
            this.app.observer.sync(this.$clickItem);

            this.oldY = 0;
            this.dragging = false;
            this._trashDragItem();
        },
        _move: function(e) {
            if (!this.$dragItem && !this.dragging) {
                return;
            }

            e.preventDefault();


            this.app.observer.trigger = false;
            var framePos = this.app.editor.getFrameRect();

            // direction & delta
            var direction = false;
            var deltaY = (this.oldY === 0) ? 0 : this.oldY - e.pageY;
            if (deltaY > 0) {
                direction = 'up';
            } else if (deltaY < 0) {
                direction = 'down';
            }

            // env
            var tolerance = 40;
            var isScrollTarget = this.app.scroll.isTarget();
            var isFrameScroll = this._isFrameScroll();
            var docScrollTop = this.app.$doc.scrollTop();
            var $target = (isScrollTarget) ? this.app.scroll.getTarget() : this.app.$doc;
            var scrollTop = (isFrameScroll) ? this.app.editor.getDoc().scrollTop() : $target.scrollTop();

            // move
            this._moveItem(this.$dragItem, deltaY);
            this.oldY = e.pageY;

            // autoscroll
            var end, startStop = false;
            if (isScrollTarget) {
                end = $target.height() + $target.offset().top - tolerance;
            }
            else if (isFrameScroll) {
                end = framePos.bottom - tolerance;
                endWin = this.app.$win.height() + docScrollTop - tolerance;
                if (endWin < end) {
                    end = endWin;
                }
            }
            else {
                startStop = !this.app.toolbar.isSticky();
                end = this.app.$win.height() + scrollTop - tolerance;
            }

            var $toolbar = this.app.container.get('toolbar');
            var toolbarHeight = $toolbar.height();
            var scrollPoint = (isFrameScroll) ? e.pageY + framePos.top - scrollTop : e.pageY + framePos.top;
            var start = $toolbar.offset().top + toolbarHeight + tolerance;

            // scroll up
            if (direction === 'up' && scrollTop > 0 && scrollPoint < start && startStop === false) {
                this._scroll(-10);
            }

            // scroll down
            else if (direction === 'down' && scrollPoint > end) {
                this._scroll(10);
            }

            // place
            var selector = (this.parentType === 'layer') ? ['block'] : false;
            var column = !(this.parentType === 'column');
            var elms = this.parent.getElements(selector, ['grid', 'column'], column);
            var len = elms.length;

            // place to another block
            if (this.parentType === 'block') {
                var layer = this.parent.getParent('layer');
                var $currentBlock = this.parent.getElement();
                var blocks = layer.getElements(['block', 'grid']);

                for (var a = 0; a < blocks.length; a++) {
                    var subBlock = blocks.eq(a).get();
                    if (subBlock === this.$clickItem.get() || subBlock === $currentBlock.get()) {
                        continue;
                    }

                    if (this._isOver(this.dom(subBlock))) {
                        var func = (direction === 'up') ? 'append' : 'prepend';
                        var $block = this.dom(subBlock);
                        var blockInstance = $block.dataget('instance');
                        var $blockTarget = blockInstance.getTarget();
                        var $blockSource = blockInstance.getSource();

                        if (blockInstance.type === 'grid') {
                            $blockTarget = blockInstance.$element;
                            func = (direction === 'up') ? 'after' : 'before';
                        }

                        var itemInstance = this.$clickItem.dataget('instance');
                        var $itemSource = itemInstance.getSource();

                        $blockTarget[func](this.$clickItem);
                        $blockSource[func]($itemSource);

                        this._buildInstance(itemInstance);
                    }
                }
            }

            // place inside block
            for (var b = 0; b < len; b++) {
                var subItem = elms.eq(b).get();

                if (subItem === this.$clickItem.get()) {
                    continue;
                }

                if (this._isOver(this.dom(subItem))) {
                    this._swapItems(subItem);
                }
            }

        },
        _scroll: function(step) {
            var $target = (this.app.scroll.isTarget()) ? this.app.scroll.getTarget() : this.app.$win;
            var isFrameScroll = this._isFrameScroll();
            if (isFrameScroll) {
                $target = this.app.editor.getWin();
            }

            var scrollY = $target.scrollTop();
            $target.scrollTop(scrollY + step);
        },
        _buildInstance: function(instance) {
            this.instance = instance;

            var type = this.instance.getType();

            this.parentType = (type === 'block') ? 'layer' : 'block';
            if (this.instance.getParent('column')) {
                this.parentType = 'column';
            }

            this.parent = (this.parentType === 'layer') ? this.instance.getParent('layer') : this.instance.getParent(this.parentType);
        },
        _swapItems: function(target) {

            var y = this.$dragItem.offset().top;
            var $item = this.$clickItem;
            var $target = this.dom(target);
            var itemInstance = $item.dataget('instance');
            var targetInstance = $target.dataget('instance');
            var $itemSource = itemInstance.getSource();
            var $targetSource = targetInstance.getSource();

            var offset = $target.offset();
            var height = $target.height()/2;
            var func = (height + offset.top > y) ? 'before' : 'after';

            $target[func]($item);
            $targetSource[func]($itemSource);
        },
        _stopEvents: function() {
            if (this.$win) {
                this.$btn.off('.' + this.prefix + '-reorder');
                this.$win.off('.' + this.prefix + '-reorder');
            }
        },
        _isFrameScroll: function() {
            var frameHeight = this.app.editor.getFrame().height();
            var bodyHeight =  this.app.editor.getBody().height();

            return (bodyHeight > frameHeight);
        },
        _isOver: function($target) {

            var y = this.$dragItem.offset().top;
            var offset = $target.offset();
            var height = $target.height();

            return (y > offset.top && y < (offset.top + height));
        },
        _moveItem: function($item, deltaY) {
            var top = $item.offset().top;
            top -= deltaY;

            $item.css('top', top + 'px');
        },
        _makeDragItem: function(item) {
            this._trashDragItem();

            var $item = this.dom(item);
            var offset = $item.offset();

            this.$clickItem = $item;
            this.$clickItem.addClass(this.prefix + '-drag-active');

            var $cloned = $item.clone();
            $cloned.removeClass(this.prefix + '-drag-active ' + this.prefix + '-element-active');

            var $dragItem = this.dom('<div>').addClass(this.prefix + '-dragging');
            $dragItem.append($cloned);
            $dragItem.css({
                'opacity': 0.95,
                'position': 'absolute',
                'z-index': 999,
                'left': offset.left + 'px',
                'top': offset.top + 'px',
                'width': $item.width() + 'px'
            });

            this.app.editor.getBody().append($dragItem);

            return $dragItem;
        },
        _trashDragItem: function() {
            if (this.$dragItem && this.$clickItem) {
                this.$clickItem.removeClass(this.prefix + '-drag-active');
                this.$clickItem = null;

                this.$dragItem.remove();
                this.$dragItem = null;
            }
        }
    });
})(Revolvapp);