# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
        ('feeds', '0003_auto_20150604_0641'),
    ]

    operations = [
        migrations.AlterField(
            model_name='feeditem',
            name='feed',
            field=models.ForeignKey(related_name='items', to='feeds.Feed'),
        ),
        migrations.AlterField(
            model_name='feeditem',
            name='published',
            field=models.DateTimeField(null=True),
        ),
    ]
