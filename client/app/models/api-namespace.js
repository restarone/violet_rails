import Model, { attr } from '@ember-data/model';

export default class ApiNamespaceModel extends Model {
  @attr('string') name;
  @attr('string') slug;
  @attr('number') version;
  @attr properties;
  @attr('boolean') requiresAuthentication;
  @attr namespaceType;
}
