# Emergency Feature

Sometimes pushing a regular update isn't gonna cut it. Maybe a serious security incident happened that can not be rectified immediately via software. Maybe the core maintainer is going to jail. Maybe the end of the world is nigh. Whatever the reason; if *something* has happened that needs the attention of your user base quickly and reliably you can use the emergency feature you're currently looking at.

## How

In your server-side configuration add the following snippet with a URL of your choice that should open on the clients' machine next time the updater runs:

!!! example "Example JSON snippet"
    ```json
    {
        "instance": {
            "emergencyUrl": "https://docs.nefarius.at/projects/Vicius/Emergency-Feature/"
        }
    }
    ```

No matter if the local software is up to date; if the `emergencyUrl` value is set on the server, it will get opened on the client as soon as the next check-cycle is run via Task Scheduler.

!!! danger "This is a powerful mechanism, do not abuse it!"
    Obviously your users will not shower you with praise if you push a random URL on them every day; only set this value if you have a good, unavoidable reason to do so! You have been warned ❤
