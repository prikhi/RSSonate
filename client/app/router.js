import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('feed', function() {});
  this.route('feeds', function() {
    this.route('feed', {
      path: ':feed_id'
    });
  });
});

export default Router;
