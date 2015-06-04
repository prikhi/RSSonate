'''Store information for RSS Feeds.'''
import datetime
import os
import urllib

from django.core.files import File
from django.db import models
import feedparser


class Feed(models.Model):
    '''Information on a single RSS Feed'''
    # RSS Specs
    feed_url = models.URLField(max_length=500, unique=True)
    title = models.CharField(max_length=200, blank=True)
    description = models.CharField(max_length=200, blank=True)
    image = models.ImageField(upload_to='feed-icons/', null=True)
    channel_link = models.URLField(max_length=200, blank=True)
    published = models.DateTimeField(auto_now_add=True)

    def __unicode__(self):
        return self.title or self.feed_url

    def save(self, *args, **kwargs):
        '''Fetch & Set the Feed URL's Information.'''
        feed = feedparser.parse(self.feed_url).feed
        self.title = feed.get('title', '')
        self.description = feed.get('description', '')
        self.channel_link = feed.get('link', '')
        published = feed.get('published_parsed', feed.get('updated_parsed'))
        if published is not None:
            self.published = datetime.datetime(*published[:-2])
        #if 'image' in feed and 'href' in feed.image:
        #    fetched_image = urllib.urlretrieve(feed.image.href)
        #    self.image.save(
        #        os.path.basename(feed.image.href),
        #        File(open(fetched_image[0]))
        #    )
        return super(Feed, self).save(*args, **kwargs)



class FeedItem(models.Model):
    '''A single item fetched from a Feed.'''
    # RSS Specs
    feed = models.ForeignKey('Feed')
    title = models.CharField(max_length=200)
    link = models.URLField()
    description = models.TextField()
    published = models.DateTimeField()
