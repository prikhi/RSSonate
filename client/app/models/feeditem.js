import DS from 'ember-data';

export default DS.Model.extend({
  feed: DS.belongsTo('feed'),
  title: DS.attr('string'),
  link: DS.attr('string'),
  description: DS.attr('string'),
  published: DS.attr('date')
});
