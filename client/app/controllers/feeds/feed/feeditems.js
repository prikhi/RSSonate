import Ember from 'ember';

export default Ember.Controller.extend({
  refreshFeed: function(adapter) {
    return adapter.buildURL('feed', this.get('feed').id) + 'refresh/';
  },

  actions: {
    refresh: function() {
      let adapter = this.store.adapterFor('feed');

      this.set('isReloading', true);
      adapter.ajax(this.refreshFeed(adapter), 'PUT').then(() => {
        this.get('feed').reload().then(() => {
          this.get('feed').get('items').reload().then(() => {
            this.set('isReloading', false);
          });
        });
      });
      return false;
    },
  }
});
