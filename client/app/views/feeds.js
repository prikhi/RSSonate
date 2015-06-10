import Ember from 'ember';

export default Ember.View.extend({
  didInsertElement: function() {
    /* Resize the Content Panel to the Remaining Height of the Screen */
    Ember.$(window).resize(function() {
      Ember.run.scheduleOnce('afterRender', this, function() {
        let extraSpace = 15;
        let $contentPanel = Ember.$('#content-panel');
        let $contentPanelBody = $contentPanel.find('.panel-body');
        let panelTop = $contentPanel.offset().top;
        let windowHeight = window.innerHeight;
        if (panelTop < windowHeight) {
          let panelBottom = $contentPanel.offset().top +
                            $contentPanel.height();
          let panelBodyBottom = $contentPanelBody.offset().top +
                                $contentPanelBody.height();
          let bottomPadding = panelBottom - panelBodyBottom + extraSpace;
          let newBodyHeight = windowHeight - $contentPanelBody.offset().top -
                              bottomPadding;
          $contentPanelBody.height(newBodyHeight);
        } else {
          $contentPanelBody.height('100%');
        }
      });
    });
    Ember.$(window).resize();
  },
});
