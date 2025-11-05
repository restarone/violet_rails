(function() {
    Revolvapp.add('plugin', 'code', {
        translations: {
            en: {
                "code": {
                    "save": "Save",
                    "cancel": "Cancel",
                    "edit-code": "Edit Code"
                }
            }
        },
        defaults: {
            icon: '<svg height="16" viewBox="0 0 16 16" width="16" xmlns="http://www.w3.org/2000/svg"><path d="m5.96835887 3.29212885c.40764996.38950514.40764996 1.02105872.00017391 1.41056386l-3.44937256 3.29724495 3.44937256 3.29724494c.40747605.3895052.40747605 1.0210587-.00017391 1.4105639-.20365107.1948357-.47078005.2922535-.73773512.2922535-.26712899 0-.53408406-.0972516-.73790904-.2920873l-4.18710767-4.00260999c-.40747605-.38950514-.40747605-1.02105872 0-1.41056386l4.18710767-4.00261c.40764996-.38950513 1.06851594-.38950513 1.47564416 0zm5.53892643 0 4.1871077 4.00261c.407476.38950514.407476 1.02105872 0 1.41056386l-4.1871077 4.00244379c-.203825.1948357-.470954.2922535-.737909.2922535-.2669551 0-.5340841-.0974178-.7377352-.2920873-.40764993-.3895051-.40764993-1.0210587-.0001739-1.4105638l3.4493726-3.29741124-3.4493726-3.29724495c-.40747603-.38950514-.40747603-1.02105872.0001739-1.41056386.4074761-.38950513 1.0683421-.38950513 1.4756442 0z"/></svg>'
        },
        popups: {
            base: {
                width: '600px',
                title: '## code.edit-code ##',
                form: {
                    'code': { type: 'textarea', rows: '8' }
                },
                footer: {
                    save: { title: '## code.save ##', command: 'code.save', type: 'primary' },
                    cancel: { title: '## code.cancel ##', close: true }
                }
            }
        },
        init: function() {},
        start: function() {
            this.app.control.add('code', {
                title: '## code.edit-code ##',
                icon: this.opts.code.icon,
                command: 'code.edit'
            });
        },
        edit: function() {
            var instance = this.app.component.get();
            var code = instance.getSource().get().outerHTML;

            code = this.app.content.removeTemplateUtils(code);
            code = this.app.tidy.parse(code);

            var stack = this.app.popup.create('code', this.popups.base);
            stack.setData({ code: code });

            this.app.popup.open({ focus: 'code' });

            // event
            stack.getInput('code').on('keydown', this.app.input.handleTextareaTab.bind(this));
        },
        save: function(stack) {
            var data = stack.getData();
            this.app.popup.close();

            var code = data.code.trim();
            if (code === '') {
                return;
            }

            // replace
            this.app.component.replaceSource(code);
        }
    });
})(Revolvapp);