import Ember from 'ember';

export default {
  name: 'ember-cli-rails-addon-csrf',

  initialize() {
    if (Ember.$ && Ember.$.ajaxPrefilter) {
      Ember.$.ajaxPrefilter((options, originalOptions, xhr) => {
        const token = Ember.$('meta[name="csrf-token"]').attr('content');
        xhr.setRequestHeader('X-CSRF-Token', token);
      });
    }
  },
};
