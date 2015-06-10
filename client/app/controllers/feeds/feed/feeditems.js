import Ember from 'ember';

export default Ember.Controller.extend({

  filterInput: '',
  clearFilterOnFeedChange: Ember.observer('feed.id', function() {
   this.set('filterInput', '');
  }),
  filteredResults: Ember.computed('model', '@each.title', 'filterInput', function() {
    let items = this.get('model');
    let filterInput = this.get('filterInput').toLowerCase();
    if (filterInput === '') { return items; }
    return items.filter(item => {
      return item.get('title').toLowerCase().indexOf(filterInput) !== -1;
    });
  }),

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
