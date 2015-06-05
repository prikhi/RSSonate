import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.modelFor('feeds.feed').get('items').reload();
  },
  setupController: function(controller, model) {
    this._super(controller, model);
    controller.set('feed', this.modelFor('feeds.feed'));
  }
});
