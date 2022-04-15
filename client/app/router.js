import EmberRouter from '@ember/routing/router';
import config from 'client/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('api-resources', function () {
    this.route('resource', { path: '/:version/:slug' });
  });
});
