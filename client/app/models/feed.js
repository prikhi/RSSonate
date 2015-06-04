import DS from 'ember-data';

export default DS.Model.extend({
  feedUrl: DS.attr('string'),
  title: DS.attr('string'),
  description: DS.attr('string'),
  channelLink: DS.attr('string'),
  published: DS.attr('date')
});
