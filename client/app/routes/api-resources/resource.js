import Route from '@ember/routing/route';
import fetch from "fetch";

export default class ResourceRoute extends Route {
  async model(params) {
    console.log(params)
    const response = await fetch(`/api/${params.version}/${params.slug}`);
    let apiResources = await response.json();
    console.log(apiResources.data)
    return apiResources.data;
  }
}
