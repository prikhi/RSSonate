import Ember from 'ember';
let disableIfNone= function(name) {
  return function() {
    return this.get('buttonClass') + (this.get(name) ? '' : ' disabled');
  };
};

export default Ember.Component.extend({
  buttonClass: 'btn btn-primary',
  nextItemClass: Ember.computed(
    'nextItem', disableIfNone('nextItem')),
  previousItemClass: Ember.computed(
    'previousItem', disableIfNone('previousItem')),
});
