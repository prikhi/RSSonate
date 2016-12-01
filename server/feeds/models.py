"""Store information for RSS Feeds."""
import datetime
import os
import threading
import urllib

from django.core.files import File
from django.db import models
import feedparser


class Feed(models.Model):
    """Information on a single RSS Feed"""

    # RSS Specs
    feed_url = models.URLField(max_length=500, unique=True)
    title = models.CharField(max_length=200, blank=True)
    description = models.CharField(max_length=200, blank=True)
    image = models.ImageField(upload_to='feed-icons/', null=True, blank=True)
    channel_link = models.URLField(max_length=200, blank=True)
    published = models.DateTimeField(auto_now_add=True)

    def __unicode__(self):
        """A Feed is identified by it's title or URL."""
        return self.title or self.feed_url

    def save(self, *args, **kwargs):
        """Fetch & Set the Feed URL's Information."""
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
        self.full_clean()
        self.async_update_items()
        return super(Feed, self).save(*args, **kwargs)

    def async_update_items(self):
        """Update the Feed in a separate thread."""
        UpdateFeedThread(self).start()

    def update_items(self):
        """Retrieve and create new items."""
        entries = feedparser.parse(self.feed_url).entries

        new_items = []
        for entry in entries:
            item_entered = self.items.filter(entry_id=entry['id']).exists()
            if not item_entered:
                item = FeedItem(feed=self, entry_id=entry['id'])
                item.title = entry.get('title', 'Feed Has No Title!')
                item.link = entry.get('link', '')
                item.description = entry.get('description', '')
                published = entry.get('published_parsed')
                if published:
                    item.published = datetime.datetime(*published[:-2])
                item.save()
                new_items.append(item)
        return new_items


class FeedItem(models.Model):
    """A single item fetched from a Feed."""

    # RSS Specs
    feed = models.ForeignKey('Feed', related_name='items')
    entry_id = models.CharField(max_length=200)
    title = models.CharField(max_length=200)
    link = models.URLField()
    description = models.TextField()
    published = models.DateTimeField(null=True)

    class Meta(object):
        ordering = ('-published',)


class UpdateFeedThread(threading.Thread):
    """Pull the latest FeedItems from a Feed."""

    def __init__(self, feed, **kwargs):
        """A Feed is required to be passed."""
        self.feed = feed
        super(UpdateFeedThread, self).__init__(**kwargs)

    def run(self):
        """Add New FeedItems."""
        self.feed.update_items()
