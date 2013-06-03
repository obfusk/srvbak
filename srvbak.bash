#!/bin/bash

# --                                                            ; {{{1
#
# File        : srvbak.bash
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-06-03
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# Usage       : srvbak.bash [ /path/to/srvbakrc ]
#
# --                                                            ; }}}1

set -e
umask 0077

date="$( date +'%FT%T' )"   # no spaces!
script="$( readlink -f "$0" )" ; scriptdir="$( dirname "$script" )"

echo "srvbak of $( hostname ) @ ${date/T/ }" ; echo

# --

before=() after=() base_dir= keep_last= gpg_opts=() gpg_key=
chown_to= chgrp_to= chmod_dirs= chmod_files=
srvbak_status= status_must_be= status_must_not_be=
baktogit= baktogit_items=() baktogit_keep_last=2
data_dir_n=0 sensitive_data_dir_n=0
postgresql_dbs=() mongo_host=localhost mongo_passfile= mongo_dbs=()
dpkg_selections=

source "$scriptdir/srvbaklib.bash"

# --

rc=
for x in "$1" /etc/srvbakrc /opt/src/srvbak/srvbakrc; do
  [ -e "$x" ] && { rc="$x"; break; }
done
[ -z "$rc" ] && die 'no srvbakrc' ; source "$rc"

for x in base_dir keep_last gpg_key; do
  eval "y=\$$x" ; [ -z "$y" ] && die "empty \$$y"
done

# --

if [[ "$VERBOSE" == [Yy]* ]]; then verbose=-v; else verbose=; fi
export VERBOSE ; dryrun="$DRYRUN"

if dryrun; then
  echo '--> DRY RUN <--'; echo '( skipping lock )'; echo
else
  run mkdir -p "$base_dir/.var" ; lock="$base_dir/.var/lock"
fi

function unlock () { dryrun || run rm -f "$lock"; }

function atexit ()
{
  unlock
  if [[ "$srvbak_status" != ok* ]]; then set_error; echo ERROR; fi
  echo
}

if ! dryrun; then
  run_hdr "[lock] $lock"
  lock "$lock" || die LOCKED ; trap unlock 0
  run_ftr
fi

get_status ; s="$srvbak_status"

if  [ -n "$status_must_be" ] && \
    [[ "$s" != $status_must_be ]]; then
  die "STATUS is $s (!= $status_must_be)"
fi
if  [ -n "$status_must_not_be" ] && \
    [[ "$s" == $status_must_not_be ]]; then
  die "STATUS is $s (== $status_must_not_be)"
fi

set_running ; trap atexit 0

# --

# 1. before
run_multi "${before[@]}"

# 2. baktogit
[ "${#baktogit_items[@]}" -ne 0 ] && \
  baktogit_tar_gpg "$baktogit" "${baktogit_items[@]}"

# 3. data
for (( i = 0; i < data_dir_n; ++i )); do
  eval 'args=( "${data_dir__'"$i"'[@]}" )'
  data_backup "${args[@]}"
done

# 4. sensitive data
for (( i = 0; i < sensitive_data_dir_n; ++i )); do
  eval 'args=( "${sensitive_data_dir__'"$i"'[@]}" )'
  sensitive_data_backup "${args[@]}"
done

# 5. postgresql
for info in "${postgresql_dbs[@]}"; do
  user="${info%%:*}" db="${info#*:}"
  pg_backup "$db" "${user:-$db}"
done

# 6. mongodb
if [ "${#mongo_dbs[@]}" -ne 0 ]; then
  process_mongo_passfile
  for db in "${mongo_dbs[@]}"; do mongo_backup "$db"; done
fi

# 7. dpkg selections
[[ "$dpkg_selections" == [Yy]* ]] && dpkg_selections_backup

# 8. fix permissions
[ -n "$chown_to"    ] && chown_to     "$chown_to"
[ -n "$chgrp_to"    ] && chgrp_to     "$chgrp_to"
[ -n "$chmod_dirs"  ] && chmod_dirs   "$chmod_dirs"
[ -n "$chmod_files" ] && chmod_files  "$chmod_files"

# 9. after
run_multi "${after[@]}"

set_ok ; echo OK

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
