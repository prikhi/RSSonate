# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
        ('feeds', '0002_auto_20150604_0252'),
    ]

    operations = [
        migrations.AddField(
            model_name='feeditem',
            name='entry_id',
            field=models.CharField(default='SENTRY', max_length=200),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='feed',
            name='feed_url',
            field=models.URLField(unique=True, max_length=500),
        ),
    ]
