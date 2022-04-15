import { module, test } from 'qunit';
import { setupTest } from 'client/tests/helpers';

module('Unit | Serializer | api namespace', function (hooks) {
  setupTest(hooks);

  // Replace this with your real tests.
  test('it exists', function (assert) {
    let store = this.owner.lookup('service:store');
    let serializer = store.serializerFor('api-namespace');

    assert.ok(serializer);
  });

  test('it serializes records', function (assert) {
    let store = this.owner.lookup('service:store');
    let record = store.createRecord('api-namespace', {});

    let serializedRecord = record.serialize();

    assert.ok(serializedRecord);
  });
});
