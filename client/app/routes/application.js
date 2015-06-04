import Ember from 'ember';

export default Ember.Route.extend({
  newFeedUrl: '',

  actions: {
    addFeed: function() {
      let feedUrl = this.get('controller.newFeedUrl');
      let feed = this.store.createRecord('feed', {feedUrl: feedUrl});
      feed.save().then(() => {
        this.set('controller.newFeedUrl', '');
      }).catch(reason => {
        feed.deleteRecord();
        this.set('controller.errors', reason.errors.feedUrl);
      });
    }
  }
});
