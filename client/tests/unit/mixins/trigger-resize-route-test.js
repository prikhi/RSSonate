import Ember from 'ember';
import TriggerResizeRouteMixin from '../../../mixins/trigger-resize-route';
import { module, test } from 'qunit';

module('Unit | Mixin | trigger resize route');

// Replace this with your real tests.
test('it works', function(assert) {
  var TriggerResizeRouteObject = Ember.Object.extend(TriggerResizeRouteMixin);
  var subject = TriggerResizeRouteObject.create();
  assert.ok(subject);
});
