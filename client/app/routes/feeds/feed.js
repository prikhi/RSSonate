import Ember from 'ember';
import scrollPanelToItem from 'client/utils/scroll-panel-to-item';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    this._super(controller, model);
    Ember.run.scheduleOnce('afterRender', this, function() {
      /* Scroll the Feeds nav to the selected item */
      scrollPanelToItem('#feeds-panel', 'ul li a.active');
    });
  }
});
