# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
        ('feeds', '0004_auto_20150604_0838'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='feeditem',
            options={'ordering': ('-published',)},
        ),
        migrations.AlterField(
            model_name='feed',
            name='image',
            field=models.ImageField(null=True, upload_to=b'feed-icons/', blank=True),
        ),
    ]
