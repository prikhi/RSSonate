RSSonate
--------

A web-based RSS reader built with Elm on top of a Django API server.


    cd server
    pip install -r requirements.py
    ./manage.py migrate
    ./manage.py runserver 0.0.0.0:8000

    cd client
    npm install
    npm run dev

    firefox http://localhost:7000

You can use the `refresh_feeds` management command along with a cronjob to
automatically keep your feeds up to date:

    $ crontab -e
    */360 * * * * bash -c 'source ~/.virtualenvs/rssonate/bin/activate; ~/Projects/RSSonate/server/manage.py refresh_feeds'

![RSSonate Screenshot](./screenshot.png)
