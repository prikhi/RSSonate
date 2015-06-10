import Ember from 'ember';
import scrollPanelToItem from 'client/utils/scroll-panel-to-item';
import TriggerResizeRoute from '../../../../mixins/trigger-resize-route';

export default Ember.Route.extend(TriggerResizeRoute, {
  afterModel: function() {
  },
  setupController: function(controller, model) {
    Ember.run.scheduleOnce('afterRender', this, function() {
      /* Scroll the Items table to the selected item */
      scrollPanelToItem('#items-panel', '.table tr.active');
      Ember.$('#content-panel .panel-body')[0].scrollTop = 0;
      Ember.$('#content-panel .panel-body')[0].scrollLeft = 0;
    });
    Ember.run.scheduleOnce('afterRender', this, function() {
    });
    this._super(controller, model);
  }
});
