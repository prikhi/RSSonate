from django.shortcuts import get_object_or_404
from rest_framework import viewsets
from rest_framework.decorators import detail_route
from rest_framework.response import Response

from .models import Feed, FeedItem
from .serializers import FeedSerializer, FeedItemSerializer


class FeedViewSet(viewsets.ModelViewSet):
    """API endpoint that allows feeds to be added, edited or viewed."""

    queryset = Feed.objects.all()
    serializer_class = FeedSerializer

    @detail_route(methods=['put'])
    def refresh(self, request, pk=None):
        """API Endpoint for fetching the latest items from a Feed."""
        feed = get_object_or_404(Feed, id=pk)
        new_items = feed.update_items()
        data = FeedItemSerializer(new_items, many=True).data
        return Response({"results": data})


class FeedItemViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint that allows feeds to be added, edited or viewed."""

    queryset = FeedItem.objects.all()
    serializer_class = FeedItemSerializer
    filter_fields = ('feed',)
