import Route from '@ember/routing/route';
import fetch from 'fetch';

export default class ResourceRoute extends Route {
  async model(params) {
    const response = await fetch(`/api/${params.version}/${params.slug}`);
    let apiResources = await response.json();
    return apiResources.data;
  }
}
