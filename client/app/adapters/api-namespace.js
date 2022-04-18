import JSONAPIAdapter from '@ember-data/adapter/json-api';
import fetch from 'fetch';

export default class ApiNamespaceAdapter extends JSONAPIAdapter {
  namespace = '/api/';
  pathForType(modelName) {
    return 'resources';
  }
}
