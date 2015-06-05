import Ember from 'ember';

export default Ember.Controller.extend({
  needs: ["feeds/feed"],

  nextItem: Ember.computed(
    'model', 'controllers.feeds/feed.model.items.[]', function() {
      /* Next is Younger, Items is in descening age, so we get the previous */
      let items = this.get('controllers.feeds/feed.model.items.[]');
      let index = items.indexOf(this.get('model'));
      return items.objectAt(index - 1);
  }),

  previousItem: Ember.computed(
    'model', 'controllers.feeds/feed.model.items.[]', function() {
      /* Previous is Older, Items is in descending age, so we get the next */
      let items = this.get('controllers.feeds/feed.model.items.[]');
      let index = items.indexOf(this.get('model'));
      return items.objectAt(index + 1);
  }),
});
