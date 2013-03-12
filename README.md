[]: {{{1

    File        : README.md
    Maintainer  : Felix C. Stegerman <flx@obfusk.net>
    Date        : 2013-03-12

    Copyright   : Copyright (C) 2013  Felix C. Stegerman
    Version     : 0.0.1

[]: }}}1

## TODO

  * test!
  * fix ls: path !!!
  * remove echo in rm!
  * remote sync!

## Description
[]: {{{1

  srvbak - server backup (cron job)

  srvbak backups/dumps configuration files (using baktogit [2]), data,
  and databases (currently mongodb and postgresql); it keeps a
  specified number of older backups, removing obsolete ones.

  See \*.sample for examples.

[]: }}}1

## Usage
[]: {{{1

    $ cp -i srvbakrc.sample /path/to/srvbakrc
    $ vim /path/to/srvbakrc
    $ /path/to/srvbak /path/to/srvbakrc

  NB: keep your password files safe!

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

[]: }}}1

[]: ! ( vim: set tw=70 sw=2 sts=2 et fdm=marker : )
