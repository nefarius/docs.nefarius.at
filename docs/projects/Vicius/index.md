# About Vīcĭus

[![GitHub](https://img.shields.io/badge/GitHub-yellowgreen?logo=github)](https://github.com/nefarius/vicius) ![Maintained](https://img.shields.io/badge/Project%20actively%20maintained-brightgreen)

Nefarius' [nŏvīcĭus](https://latinitium.com/latin-dictionaries/?t=lsn31290) (or just vicius for short) is a universal software updater agent for Windows. It's a self-contained executable that can be shipped alongside your software product(s) and takes care of keeping them up-to-date out in the field. It requires only minimal configuration and backend server capabilities (any static web server will do) while offering enough flexibility and optional features to the more adventurous users.

On this site you can find the extended documentation teaching you how to get it up and running in a few moments.

## Architecture

The only requirement you need to *at least* fulfil is to provide a web server providing the [remote update configuration file](Remote-Configuration.md). The [Server Discovery](Server-Discovery.md) describes in detail how this is achieved.

The updater is meant to be distributed alongside the product it will watch over, e.g. via a setup package created with [WiX](https://wixtoolset.org/), [Inno Setup](https://jrsoftware.org/isinfo.php), [Advanced Installer](https://www.advancedinstaller.com/) and alike. Once placed on the client machine, it requires [very little effort to be ready to run](Command-Line-Arguments.md#-install). It will be run periodically by Task Scheduler and contact the pre-configured server for the latest [remote update configuration file](Remote-Configuration.md) and makes decisions based on its content.

## Workflow

Once the updater is run (either by the user or automatically) it will [check if the local product installation is outdated](Product-Detection.md) and if so, offers the user a simple notification window with choices on next steps. The user can then decide to check out the update summary (a free text that should be used as a list of changes) and start downloading and running the update. Alternatively the update can be postponed or help resources displayed, if configured.
