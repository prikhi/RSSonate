from rest_framework import viewsets

from rssinate.filters import CoalesceFilterBackend
from .models import Feed, FeedItem
from .serializers import FeedSerializer, FeedItemSerializer


class FeedViewSet(viewsets.ModelViewSet):
    '''API endpoint that allows feeds to be added, edited or viewed.'''
    queryset = Feed.objects.all()
    serializer_class = FeedSerializer


class FeedItemViewSet(viewsets.ReadOnlyModelViewSet):
    '''API endpoint that allows feeds to be added, edited or viewed.'''
    queryset = FeedItem.objects.all()
    serializer_class = FeedItemSerializer
    filter_backends = (CoalesceFilterBackend,)
