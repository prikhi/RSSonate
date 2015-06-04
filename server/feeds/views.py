from rest_framework import viewsets

from .models import Feed
from .serializers import FeedSerializer


class FeedViewSet(viewsets.ModelViewSet):
    '''API endpoint that allows feeds to be added, edited or viewed.'''
    queryset = Feed.objects.all()
    serializer_class = FeedSerializer
