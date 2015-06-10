import Ember from 'ember';

export default Ember.Controller.extend({
  needs: ["feeds/feed"],

  items: Ember.computed.alias('controllers.feeds/feed.model.items.[]'),

  nextItem: Ember.computed('model', 'items', function() {
      /* Next is Younger & Items is in descening age, so we get the previous
       * item in the array */
      let items = this.get('items');
      let index = items.indexOf(this.get('model'));
      return items.objectAt(index - 1);
  }),

  previousItem: Ember.computed('model', 'items', function() {
      /* Previous is Older and Items is in descending age, so we get the next
       * item in the array */
      let items = this.get('items');
      let index = items.indexOf(this.get('model'));
      return items.objectAt(index + 1);
  }),

});
