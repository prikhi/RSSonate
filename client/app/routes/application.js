import Ember from 'ember';

export default Ember.Route.extend({
  newFeedUrl: '',

  actions: {
    addFeed: function() {
      var feedUrl = this.get('controller.newFeedUrl');
      var feed = this.store.createRecord('feed', {feedUrl: feedUrl});
      feed.save().then(
        () => { this.set('controller.newFeedUrl', ''); },
        () => { feed.destroyRecord(); }
      );
    }
  }
});
