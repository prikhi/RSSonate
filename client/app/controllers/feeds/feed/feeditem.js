import Ember from 'ember';

export default Ember.Controller.extend({
  needs: ["feeds/feed"],

  nextItem: function() {
    /* Next is Younger, Items is in descening age, so we get the previous */
    var items = this.get('controllers.feeds/feed.model.items.[]');
    var index = items.indexOf(this.get('model'));
    return items.objectAt(index - 1);
  }.property('model'),

  previousItem: function() {
    /* Previous is Older, Items is in descending age, so we get the next */
    var items = this.get('controllers.feeds/feed.model.items.[]');
    var index = items.indexOf(this.get('model'));
    return items.objectAt(index + 1);
  }.property('model'),
});
