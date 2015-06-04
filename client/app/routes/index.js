import Ember from 'ember';

export default Ember.Route.extend({
  setupController: function() {
    /* Just redirect to the Feeds route */
    this.transitionTo('feeds');
  }
});
