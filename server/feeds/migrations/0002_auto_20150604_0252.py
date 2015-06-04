# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
        ('feeds', '0001_initial'),
    ]

    operations = [
        migrations.RenameField(
            model_name='feed',
            old_name='url',
            new_name='feed_url',
        ),
        migrations.AlterField(
            model_name='feed',
            name='channel_link',
            field=models.URLField(blank=True),
        ),
        migrations.AlterField(
            model_name='feed',
            name='description',
            field=models.CharField(max_length=200, blank=True),
        ),
        migrations.AlterField(
            model_name='feed',
            name='image',
            field=models.ImageField(null=True, upload_to=b'feed-icons/'),
        ),
        migrations.AlterField(
            model_name='feed',
            name='published',
            field=models.DateTimeField(auto_now_add=True),
        ),
        migrations.AlterField(
            model_name='feed',
            name='title',
            field=models.CharField(max_length=200, blank=True),
        ),
    ]
