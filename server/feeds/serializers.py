from rest_framework import serializers

from .models import Feed, FeedItem


class FeedItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedItem
        fields = ('id', 'title', 'description', 'link', 'published', 'feed')


class FeedSerializer(serializers.ModelSerializer):
    class Meta:
        model = Feed
        fields = ('id', 'feed_url', 'title', 'description', 'image',
                  'channel_link', 'published', 'items')
        read_only_fields = ('title', 'description', 'image', 'channel_link',
                            'published', 'items')
