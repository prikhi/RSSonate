import Ember from 'ember';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    this._super(controller, model);
    /* Always reload the feed & items when visitng this route */
    model.reload();
    model.get('items').reload();
  }
});
