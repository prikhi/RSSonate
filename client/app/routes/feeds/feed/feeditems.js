import Ember from 'ember';
import TriggerResizeRoute from '../../../mixins/trigger-resize-route';

export default Ember.Route.extend(TriggerResizeRoute, {
  model: function() {
    return this.modelFor('feeds.feed').get('items').reload();
  },
  setupController: function(controller, model) {
    controller.set('feed', this.modelFor('feeds.feed'));
    this._super(controller, model);
  },
});
