import Ember from 'ember';

export default Ember.Route.extend({
  newFeedUrl: '',

  actions: {
    addFeed: function() {
      /* Add a Feed from the URL input in the nav */
      let feedUrl = this.get('controller.newFeedUrl');
      let feed = this.store.createRecord('feed', {feedUrl: feedUrl});
      feed.save().then(() => {
        this.set('controller.newFeedUrl', '');
      }).catch(() => {
        feed.deleteRecord();
        this.set('controller.errors', 'This Feed Already Exists');
      });
    }
  }
});
