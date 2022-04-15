import Route from '@ember/routing/route';
import fetch from 'fetch';
import { service } from '@ember/service';

export default class ApiResourcesRoute extends Route {
  @service store;
  async model() {
    return this.store.findAll('api-namespace');
  }
}
