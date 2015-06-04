from rest_framework import serializers

from .models import Feed


class FeedSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Feed
        fields = ('id', 'feed_url', 'title', 'description', 'image',
                  'channel_link', 'published')
        read_only_fields = ('title', 'description', 'image', 'channel_link',
                            'published')
