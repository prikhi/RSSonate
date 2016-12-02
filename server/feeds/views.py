from django.shortcuts import get_object_or_404
from rest_framework import viewsets
from rest_framework.decorators import detail_route
from rest_framework.response import Response

from .models import Feed, FeedSubscription, FeedItem, UserItem
from .serializers import FeedSerializer, FeedItemSerializer


class FeedViewSet(viewsets.GenericViewSet):
    """API endpoint that allows a User's feeds to be created or listed."""

    queryset = Feed.objects.all()

    def create(self, request):
        """Create a Feed & Subscription if necessary."""
        (feed, _) = self.get_queryset().get_or_create(
            feed_url=request.data['feed_url'])
        (_, _) = FeedSubscription.objects.get_or_create(
            feed=feed, user=request.user)
        data = FeedSerializer(feed).data
        return Response(data)

    def list(self, request):
        """List only Feeds that the User has a Subscription for."""
        subscribed_feeds = self.get_queryset().filter(
            subscriptions__user=request.user)
        data = FeedSerializer(subscribed_feeds, many=True).data
        return Response(data)

    @detail_route(methods=['put'])
    def refresh(self, request, pk=None):
        """Update the Feed's Items, returning any new Items."""
        feed = self.get_object()
        new_items = feed.update_items()
        data = FeedItemSerializer(new_items, many=True).data
        return Response({"results": data})


class FeedItemViewSet(viewsets.GenericViewSet):
    """API endpoint that allows a User's FeedItem's to be edited & listed."""

    queryset = FeedItem.objects.all()

    def list(self, request):
        subscribed_feeds = Feed.objects.filter(
            subscriptions__user=request.user)
        if 'feed' in request.GET:
            subscribed_feeds = subscribed_feeds.filter(id=request.GET['feed'])
        items = []
        for feed in subscribed_feeds:
            feed_items = FeedItem.objects.filter(feed=feed)
            for item in feed_items:
                data = {"id": item.id, "feed": feed.id, "title": item.title,
                        "link": item.link, "description": item.description,
                        "published": item.published}
                (user_item, _) = UserItem.objects.get_or_create(
                    item=item, user=request.user)
                data['is_unread'] = user_item.is_unread
                items.append(data)
        return Response(items)

    @detail_route(methods=['PUT'])
    def read(self, request, pk=None):
        """Mark the User's FeedItem as Read."""
        user_item = get_object_or_404(UserItem, item_id=pk, user=request.user)
        user_item.is_unread = False
        user_item.save()
        return Response("ok")
