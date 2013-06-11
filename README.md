[]: {{{1

    File        : README.md
    Maintainer  : Felix C. Stegerman <flx@obfusk.net>
    Date        : 2013-06-04

    Copyright   : Copyright (C) 2013  Felix C. Stegerman
    Version     : 0.4.3

[]: }}}1

## TODO
### Maybe

  * options to not use gpg for databases ?!
  * sign/hash?
  * relative path/hash links?

## Description
[]: {{{1

  srvbak - server backup (cron job)

  srvbak.bash backs up configuration files, data, sensitive data, and
  databases (currently postgresql and mongodb).  It keeps the
  specified number of older backups, removing obsolete ones.  Services
  can be stopped and restarted, if needed.

  See \*.sample for (annotated) configuration examples.

  If you want to know how files are organized, see tree.sample.

  To use baktogit [2] to back up configuration files, set it up (with
  a repository not in srvbak's directory), then configure srvbak to
  use it.

  To use gpg for secure backups, you will need (to create) a gpg key;
  see GPG.

  There is an optional cron job that runs srvbak daily, sending a
  report per email using mailer [3].

  To securely and automatically copy the backups (w/ rsync and ssh) to
  e.g. a NAS, you can use cpbak [4].

  It should also be possible to create a custom backup script using
  the srvbaklib.bash library.

[]: }}}1

## Security Warning
[]: {{{1

  You should be careful with files like `/etc/shadow` that must remain
  secret.  srvbak does its best to keep everything secure, by setting
  a `umask` of `0077` and encrypting everything but non-sensitive
  data.  When using baktogit, you should read its Security Warning.

  Files you may want to exclude from backups, or at least be very
  careful with (e.g. by using encryption) are: `/etc/shadow*`,
  `/etc/ssh/ssh_host_*_key` and any other private keys and
  configuration files with passwords.

[]: }}}1

## srvbak.bash steps
[]: {{{1

  1. commands to run before (e.g. stop services)
  2. baktogit + tar + gpg
  3. non-sensitive data w/ rsync (incrementally, using cp -l)
  4. sensitive data w/ tar + gpg
  5. postgresql w/ pgdump + gpg
  6. mongodb w/ mongodump + tar + gpg
  7. dpkg selections
  8. fix permissions (chown/chgrp/chmod)
  9. commands to run after

#

  You can also specify commands to run after, even on failure; e.g.
  to (re)start services; they are run if all goes well, or an error
  occurs after the actual backup (i.e. step 1) has begun.

  Each step is optional.

  A lock file (`ln -s $$ $base_dir/.var/lock`) is used to prevent
  concurrent backups; you can create+rm this lock file yourself when
  e.g. copying backups elsewhere.

  A status file (`$base_dir/.var/status`) is used to log the status of
  the current/last run.  It is not written until just before the
  actual backup begins -- after the configuration file has been
  processed, the lock file is created, and the previous status is
  checked.  For more information on the (contents of the) status file,
  see `srvbakrc.sample`.

[]: }}}1

## Install and Configure
[]: {{{1

    $ mkdir -p /opt/src
    $ git clone https://github.com/noxqsgit/srvbak.git /opt/src/srvbak
    $ cp -i /opt/src/srvbak/srvbakrc{.sample,}
    $ vim /opt/src/srvbak/srvbakrc

  The `srvbakrc.sample` annotated configuration file example should be
  mostly self-explanatory.

  If you set `DRYRUN=yes` in `srvbakrc` or ENV, srvbak will perform a
  trial run with no changes made; this will allow you to see what
  actions would be performed.

  When using baktogit, you'll need to `--exclude=.git` any `.git/`
  directories.

  Arguments to `data_dir` and `sensitive_data_dir` will be passed on
  to rsync and tar, respectively; as long as you only use `--exclude`,
  and `--exclude-from` (or know what you are doing), all should be
  well.  The tar command is run with the `--anchored` flag; you may
  want to consult the tar documentaion for information about this flag
  as well as the use of wildcards and slashes.

  If you use cpbak, follow its instructions (which includes creating a
  srvbak user), and then use `chgrp_to=srvbak` in srvbakrc to allow
  the srvbak user read access to the backup.

[]: }}}1

## Run
[]: {{{1

  With no arguments, looks for /etc/srvbakrc or
  /opt/src/srvbak/srvbakrc.

    $ /opt/src/srvbak/srvbak.bash /path/to/srvbakrc

[]: }}}1

## Cron
[]: {{{1

  If you want reports per email, install mailer [3].

### Either using cron.daily

    $ cp -i /opt/src/srvbak/srvbak.cron.sample /etc/cron.daily/srvbak
    $ vim /etc/cron.daily/srvbak
    $ chmod +x /etc/cron.daily/srvbak

### or with e.g. cron.2am

    $ mkdir -p /etc/cron.2am
    $ cp -i /opt/src/srvbak/crontab.2am.sample /etc/cron.d/2am

  Then:

    $ cp -i /opt/src/srvbak/srvbak.cron.sample /etc/cron.2am/srvbak
    $ vim /etc/cron.2am/srvbak
    $ chmod +x /etc/cron.2am/srvbak

[]: }}}1

## GPG
[]: {{{1

    $ gpg --gen-key           # create a gpg key pair on your computer
                              # the key id is something like 1AA35570
    $ gpg -o 1AA35570.pub --export -a 1AA35570    # export public key

    root@server$ gpg --import < 1AA35570.pub      # import
    root@server$ gpg --list-keys          # should contain 1AA35570
    root@server$ gpg --edit-key 1AA35570  # trust ultimately
    gpg> trust
    ...
    Your decision? 5
    ...
    gpg> quit

    root@server$ vim /path/to/srvbakrc    # gpg_key=1AA35570

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
