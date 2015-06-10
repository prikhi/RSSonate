import Ember from 'ember';

export default Ember.Controller.extend({
  refreshFeed: function(adapter, feed) {
    return adapter.buildURL('feed', feed.id) + 'refresh/';
  },

  actions: {
    refresh: function() {
      let adapter = this.store.adapterFor('feed');
      let model = this.get('model');
      let numberOfFeeds = model.get('length');
      let feedsProcessed = 0;

      this.set('isReloading', true);
      model.map((feed) => {
        adapter.ajax(this.refreshFeed(adapter, feed), 'PUT').then(() => {
          feed.reload().then(() => {
            feed.get('items').reload().then(() => {
              feedsProcessed++;
              this.set('refreshPercentage',
                       Math.ceil(feedsProcessed / numberOfFeeds * 100));
              if (feedsProcessed === numberOfFeeds) {
                this.set('isReloading', false);
                this.set('refreshPercentage', 0);
                Ember.$(window).resize();
              }
            });
          });
        });
      });
      Ember.$(window).resize();
      return false;
    },
  }
});
