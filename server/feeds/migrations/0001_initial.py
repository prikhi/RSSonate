# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Feed',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('url', models.URLField(max_length=500)),
                ('title', models.CharField(max_length=200)),
                ('description', models.CharField(max_length=200)),
                ('image', models.ImageField(upload_to=b'feed-icons/')),
                ('channel_link', models.URLField()),
                ('published', models.DateTimeField()),
            ],
        ),
        migrations.CreateModel(
            name='FeedItem',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('title', models.CharField(max_length=200)),
                ('link', models.URLField()),
                ('description', models.TextField()),
                ('published', models.DateTimeField()),
                ('feed', models.ForeignKey(to='feeds.Feed')),
            ],
        ),
    ]
