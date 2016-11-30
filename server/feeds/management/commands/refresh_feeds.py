from django.core.management.base import BaseCommand

from feeds.models import Feed


class Command(BaseCommand):
    help = 'Pull the latest Items from every Feed'

    def handle(self, *args, **options):
        for feed in Feed.objects.all():
            feed.async_update_items()
