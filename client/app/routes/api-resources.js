import Route from '@ember/routing/route';
import fetch from 'fetch';

export default class ApiResourcesRoute extends Route {
  async model() {
    const response = await fetch('/api/resources');
    let apiNamespaces = await response.json();
    return apiNamespaces.data;
  }
}
