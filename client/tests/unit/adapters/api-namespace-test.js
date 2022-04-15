import { module, test } from 'qunit';
import { setupTest } from 'client/tests/helpers';

module('Unit | Adapter | api namespace', function (hooks) {
  setupTest(hooks);

  // Replace this with your real tests.
  test('it exists', function (assert) {
    let adapter = this.owner.lookup('adapter:api-namespace');
    assert.ok(adapter);
  });
});
