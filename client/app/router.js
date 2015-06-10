import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('feeds', function() {
    this.route('feed', {
      path: ':feed_id',
    }, function() {
      this.route('feeditems', { path: 'items/' }, function() {
        this.route('feeditem', {
          path: ':feeditem_id',
        });
      });
      this.route('loading');
    });
  });
});

export default Router;
