import Ember from 'ember';

export default function scrollPanelToItem(panelSelector, itemSelector) {
      Ember.run({}, () => {
        let $panel = Ember.$(panelSelector);
        let $heading = $panel.find('.panel-heading');
        let $item = $panel.find(itemSelector);
        let itemAboveView = $item.offset().top <
                            $heading.offset().top + $heading.height();
        let itemBelowView = $item.offset().top + $item.height() >
                            $panel.offset().top + $panel.height();
        if (itemAboveView) {
          $item[0].scrollIntoView();
        } else if (itemBelowView) {
          $item[0].scrollIntoView(false);
        }
      });
}
