import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

module('Unit | Route | api-resources', function (hooks) {
  setupTest(hooks);

  test('it exists', function (assert) {
    let route = this.owner.lookup('route:api-resources');
    assert.ok(route);
  });
});
