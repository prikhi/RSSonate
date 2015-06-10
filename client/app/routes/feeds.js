import Ember from 'ember';
import TriggerResizeRoute from '../mixins/trigger-resize-route';

export default Ember.Route.extend(TriggerResizeRoute, {
  model: function() {
    return this.store.findAll('feed');
  },
});
