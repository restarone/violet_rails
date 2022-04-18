import Route from '@ember/routing/route';
import fetch from 'fetch';
import { service } from '@ember/service';

export default class ApiResourcesRoute extends Route {
  @service session;
  model() {
    this.session.authenticate('authenticator:devise', 'violet@rails.com',
      '123456'
    );
  }
}
