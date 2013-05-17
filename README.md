[]: {{{1

    File        : README.md
    Maintainer  : Felix C. Stegerman <flx@obfusk.net>
    Date        : 2013-05-17

    Copyright   : Copyright (C) 2013  Felix C. Stegerman
    Version     : 0.0.5

[]: }}}1

## TODO

  * review! + test!
  * remote sync! --> cpbak!

### README

  * dry run
  * tar/rsync: wildcards/slashes, anchored
  * 2am/4am/...

### Maybe

  * options to not use gpg for databases ?!

## Description
[]: {{{1

  srvbak - server backup (cron job)

  srvbak.bash backs up configuration files, data, sensitive data, and
  databases (currently postgresql and mongodb).  It keeps the
  specified number of older backups, removing obsolete ones.  Services
  can be stopped and restarted, if needed.

  See \*.sample for (annotated) configuration examples.

  To use baktogit [2] to back up configuration files, set it up (with
  a repository not in srvbak's directory), then configure srvbak to
  use it.

  To use gpg for secure backups, you will need to create a gpg key;
  see GPG.

  There is an optional cron job that runs srvbak daily, sending a
  report per email using mailer [3].

  To securely and automatically copy the backups (w/ rsync and ssh) to
  e.g. a NAS, you can use cpbak [4].

  It should also be possible to create a custom backup script using
  the srvbaklib.bash library.

[]: }}}1

## srvbak.bash steps
[]: {{{1

  1. commands to run before (e.g. stop services)
  2. baktogit + tar + gpg
  3. data w/ rsync (incrementally, using cp -l)
  4. sensitive data w/ tar + gpg
  5. postgresql w/ pgdump + tar + gpg
  6. mongodb w/ mongodump + tar + gpg
  7. commands to run after (e.g. start services)

#

  Each step is optional.

[]: }}}1

## Install
[]: {{{1

    $ mkdir -p /opt/src
    $ git clone https://github.com/noxqsgit/srvbak.git /opt/src/srvbak
    $ cp -i /opt/src/srvbak/srvbakrc{.sample,}
    $ vim /opt/src/srvbak/srvbakrc

[]: }}}1

## Run
[]: {{{1

  With no arguments, looks for /etc/srvbakrc or
  /opt/src/srvbak/srvbakrc.

    $ /opt/src/srvbak/srvbak.bash /path/to/srvbakrc

[]: }}}1

## Cron
[]: {{{1

  If you want reports per email, install mailer [2].

    $ cp -i /opt/src/srvbak/srvbak.cron.sample /etc/cron.daily/srvbak
    $ vim /etc/cron.daily/srvbak
    $ chmod +x /etc/cron.daily/srvbak

[]: }}}1

## GPG
[]: {{{1

    $ gpg --gen-key           # create a gpg key pair on your computer
                              # the key id is something like 1AA35570
    $ gpg -o 1AA35570.pub --export -a 1AA35570    # export public key
    $ ssh user@server sudo -H gpg --import < 1AA35570.pub
                              # import public key (for root@server)

    root@server$ gpg --list-keys        # should contain 1AA35570
    root@server$ vim /path/to/srvbakrc  # gpg_key=1AA35570

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

  [4] cpbak
  --- https://github.com/noxqsgit/cpbak

[]: }}}1

[]: ! ( vim: set tw=70 sw=2 sts=2 et fdm=marker : )
