/* Resizes the window upon activation of the route */
import Ember from 'ember';

export default Ember.Mixin.create({
  resizeOnActivate: Ember.on('activate', function() {
    Ember.$(window).resize();
  }),
});
