"""Store information for RSS Feeds."""
import datetime
from HTMLParser import HTMLParser
import threading

import bleach
from django.conf import settings
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.forms import ValidationError
import feedparser
import pytz


class Feed(models.Model):
    """Information on a single RSS Feed"""

    # RSS Specs
    feed_url = models.URLField(max_length=500, unique=True)
    title = models.CharField(max_length=200, blank=True)
    description = models.CharField(max_length=200, blank=True)
    channel_link = models.URLField(max_length=200, blank=True)
    published = models.DateTimeField(auto_now_add=True)

    def __unicode__(self):
        """A Feed is identified by it's title or URL."""
        return self.title or self.feed_url

    def save(self, *args, **kwargs):
        """Fetch & Set the Feed URL's Information."""
        feed = feedparser.parse(self.feed_url).feed
        if feed == {}:
            raise ValidationError("Could not parse feed.")
        html = HTMLParser()
        self.title = html.unescape(feed.get('title', ''))
        self.description = bleach.clean(feed.get('description', ''))
        self.channel_link = feed.get('link', '')
        published = feed.get('published_parsed', feed.get('updated_parsed'))
        if published is not None:
            self.published = datetime.datetime(
                *published[:-2]).replace(tzinfo=pytz.UTC)
        self.full_clean()
        super(Feed, self).save(*args, **kwargs)
        self.update_items()

    def async_update_items(self):
        """Update the Feed in a separate thread."""
        UpdateFeedThread(self).start()

    def update_items(self):
        """Retrieve and create new items."""
        entries = feedparser.parse(self.feed_url).entries
        html = HTMLParser()

        new_items = []
        for entry in entries:
            item_entered = self.items.filter(entry_id=entry['id']).exists()
            if not item_entered:
                item = FeedItem(feed=self, entry_id=entry['id'])
                item.title = html.unescape(entry.get('title', '(untitled)'))
                item.link = entry.get('link', '')
                item.description = entry.get('description', '')
                published = entry.get('published_parsed', None)
                if published is not None:
                    item.published = datetime.datetime(
                        *published[:-2]).replace(tzinfo=pytz.UTC)
                item.save()
                new_items.append(item)
        return new_items


class FeedSubscription(models.Model):
    """A Subscription to a Feed for a User."""

    feed = models.ForeignKey('Feed', related_name='subscriptions')
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    class Meta(object):
        unique_together = ('feed', 'user')


@receiver(post_save, sender=FeedSubscription)
def create_user_items(sender, instance=None, created=False, **kwargs):
    """Create UserItems for the new Subscriber, if they don't exist."""
    if created:
        for item in instance.feed.items.all():
            UserItem.objects.get_or_create(item=item, user=instance.user)


class FeedItem(models.Model):
    """A single item fetched from a Feed."""

    # RSS Specs
    feed = models.ForeignKey('Feed', related_name='items')
    entry_id = models.CharField(max_length=200)
    title = models.CharField(max_length=300)
    link = models.URLField()
    description = models.TextField()
    published = models.DateTimeField(null=True)

    class Meta(object):
        ordering = ('-published',)


@receiver(post_save, sender=FeedItem)
def create_user_item(sender, instance=None, created=False, **kwargs):
    """Create a UserItem for each Subscriber."""
    if created:
        subscriptions = FeedSubscription.objects.filter(feed=instance.feed)
        for subscription in subscriptions:
            UserItem.objects.create(item=instance, user=subscription.user)


class UserItem(models.Model):
    """A FeedItem linked to a User."""

    item = models.ForeignKey('FeedItem')
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    is_unread = models.BooleanField(default=True)
    is_favorite = models.BooleanField(default=False)

    class Meta(object):
        unique_together = ('item', 'user')


class UpdateFeedThread(threading.Thread):
    """Pull the latest FeedItems from a Feed."""

    def __init__(self, feed, **kwargs):
        """A Feed is required to be passed."""
        self.feed = feed
        super(UpdateFeedThread, self).__init__(**kwargs)

    def run(self):
        """Add New FeedItems."""
        self.feed.update_items()
