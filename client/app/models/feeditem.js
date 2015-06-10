import DS from 'ember-data';
import Ember from 'ember';

export default DS.Model.extend({
  feed: DS.belongsTo('feed'),
  title: DS.attr('string'),
  link: DS.attr('string'),
  description: DS.attr('string'),
  published: DS.attr('date'),

  formattedDate: Ember.computed('published', function() {
    return this.get('published').toLocaleDateString();
  }),
});
