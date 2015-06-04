import { moduleForModel, test } from 'ember-qunit';

moduleForModel('feeditem', 'Unit | Model | feeditem', {
  // Specify the other units that are required for this test.
  needs: ['model:feed']
});

test('it exists', function(assert) {
  var model = this.subject();
  // var store = this.store();
  assert.ok(!!model);
});
