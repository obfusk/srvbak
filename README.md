[]: {{{1

    File        : README.md
    Maintainer  : Felix C. Stegerman <flx@obfusk.net>
    Date        : 2013-05-06

    Copyright   : Copyright (C) 2013  Felix C. Stegerman
    Version     : 0.0.2

[]: }}}1

## TODO

  * test!
  * remove echo in rm!
  * remote sync!

## Description
[]: {{{1

  srvbak - server backup (cron job)

  srvbak.bash backups/dumps configuration files (using baktogit [2]),
  data (incrementally, using cp -l and rsync), and databases
  (currently postgresql and mongodb).  It keeps a specified number of
  older backups, removing obsolete ones.  Services can be stopped and
  restarted if needed.  The cron job runs srvbak, sending a report per
  email using mailer [3].

  A cron job on another server can regularly copy the backups to e.g.
  a NAS, using rsync and ssh.

  NB: when using baktogit, just set it up first, then let srvbak use
  it.

  See \*.sample for examples.

[]: }}}1

## Usage
[]: {{{1

### Install

    $ mkdir -p /opt/src
    $ git clone https://github.com/noxqsgit/srvbak.git /opt/src/srvbak
    $ cp -i /opt/src/srvbak/srvbakrc{.sample,}
    $ vim /opt/src/srvbak/srvbakrc

### Usage

  If no argument is given, searches for /etc/srvbakrc or
  /opt/src/srvbak/srvbakrc.

    $ /opt/src/srvbak/srvbak.bash [ /opt/src/srvbak/srvbakrc ]

### Cron

  First, install mailer [2].

    $ cp -i /opt/src/srvbak/srvbak.cron.sample /etc/cron.daily/srvbak
    $ vim /etc/cron.daily/srvbak
    $ chmod +x /etc/cron.daily/srvbak

[]: }}}1

## License
[]: {{{1

  GPLv2 [1].

[]: }}}1

## References
[]: {{{1

  [1] GNU General Public License, version 2
  --- http://www.opensource.org/licenses/GPL-2.0

  [2] baktogit
  --- https://github.com/noxqsgit/baktogit

  [3] mailer
  --- https://github.com/noxqsgit/mailer

[]: }}}1

[]: ! ( vim: set tw=70 sw=2 sts=2 et fdm=marker : )
