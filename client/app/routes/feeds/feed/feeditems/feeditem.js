import Ember from 'ember';
import scrollPanelToItem from 'client/utils/scroll-panel-to-item';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    this._super(controller, model);

    Ember.run.scheduleOnce('afterRender', this, function() {
      /* Scroll the Items table to the selected item */
      scrollPanelToItem('#items-panel', '.table tr.active');

      /* Resize the Content Panel to the Reminaing Height of the Screen */
      window.onresize = function() {
        let $contentPanel = Ember.$('#content-panel .panel-body');
        let panelTop = $contentPanel.offset().top;
        let windowHeight = window.innerHeight;
        if (panelTop < windowHeight) {
          $contentPanel.height(windowHeight - (panelTop + 65));
          $contentPanel.css({'overflow-y': 'scroll'});
        } else {
          $contentPanel.height('100%');
          $contentPanel.css({'overflow-y': 'hidden'});
        }
      };
      window.onresize();
    });
  }
});
