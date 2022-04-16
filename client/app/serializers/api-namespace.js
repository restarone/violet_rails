import JSONAPISerializer from '@ember-data/serializer/json-api';

export default class ApiNamespaceSerializer extends JSONAPISerializer {
  normalizeResponse(store, primaryModelClass, payload, id, requestType) {
    return super.normalizeResponse(...arguments);
  }
}
