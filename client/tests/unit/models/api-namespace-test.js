import { module, test } from 'qunit';
import { setupTest } from 'client/tests/helpers';

module('Unit | Model | api namespace', function (hooks) {
  setupTest(hooks);

  // Replace this with your real tests.
  test('it exists', function (assert) {
    let store = this.owner.lookup('service:store');
    let model = store.createRecord('api-namespace', {});
    assert.ok(model);
  });
});
