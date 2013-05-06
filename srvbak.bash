#!/bin/bash

# --                                                            ; {{{1
#
# File        : srvbak
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-03-12
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

set -e
source "$1"

export LC_COLLATE=C
date="$( date +'%FT%T' )"   # no spaces!

# Usage: run <cmd> <arg(s)>
function run () { echo "==> $@"; "$@"; echo; }

# Usage: run_multi <cmd1-with-args> <cmd2-with-args> ...
function run_multi () { local x; for x in "$@"; do run $x; done; }

# Usage: canonpath <path>
# No physical check on the filesystem, but a logical cleanup of a
# path.
function canonpath ()
{ perl -MFile::Spec -e 'print File::Spec->canonpath($ARGV[0])' "$1"; }

# Usage: hashpath <path>
# SHA1 hash of canonical path.
function hashpath ()
{ printf '%s' "$( canonpath "$1" )" | sha1sum | awk '{print $1}'; }

# --

# Usage: process_mongo_passfile
# Uses $mongo_passfile; sets $mongo_auth__${db}__{user,pass}.
function process_mongo_passfile ()
{                                                               # {{{1
  local oldifs="$IFS" db user pass
  IFS=:
  while read -r db user pass; do
    [[ "$db" =~ ^[A-Za-z0-9]+$ ]] || exit 1
    eval "mongo_auth__${db}__user=\$user"
    eval "mongo_auth__${db}__pass=\$pass"
  done < "$mongo_passfile"
  IFS="$oldifs"
}                                                               # }}}1

# Usage: ls_backups <dir>
function ls_backups () { ls "$1" | grep -E '^[0-9]{4}-'; }

# Usage: last_backup <dir>
function last_backup () { ls_backups "$1" | tail -n 1; }

# Usage: obsolete_backups <dir>
function obsolete_backups ()
{ ls_backups "$1" | head -n -"$keep_last"; }

# Usage: cp_last_backup <dir> <path>
# Copies last backup in <dir> (if one exists) to <path> using hard
# links.
# NB: call before new backup (or dir creation)!
function cp_last_backup ()
{                                                               # {{{1
  local dir="$1" path="$2"
  local last="$( last_backup "$dir" )"

  if [ -n "$last" -a -e "$last" ]; then
    run cp -alT "$last" "$path"
  fi
}                                                               # }}}1

# Usage: rm_obsolete_backups <dir>
# NB: call after new backup!
function rm_obsolete_backups ()
{                                                               # {{{1
  local dir="$1" x
  for x in $( obsolete_backups "$dir" ); do
    run echo rm -r "$x"                                         # TODO
  done
}                                                               # }}}1

# --

# Usage: pg_backup <dbname> <dbuser>
# PostgreSQL dump to $base_dir/postgresql/$dbname/$date.sql.
# Removes obsolete backups.
# Uses $PG*.
function pg_backup ()
{                                                               # {{{1
  local dbname="$1" dbuser="$2"
  local dir="$base_dir/postgresql/$dbname"
  local dump="$dir/$date".sql

  mkdir -p "$dir"
  run pg_dump "$dbname" -f "$dump" -w -U "$dbuser"

  rm_obsolete_backups "$dir"
}                                                               # }}}1

# Usage: mongo_backup <dbname>
# MongoDB dump to $base_dir/mongodb/$dbname/$date.
# Removes obsolete backups.
# Uses $mongo_{host,auth__${dbname}__{user,pass}}.
function mongo_backup ()
{                                                               # {{{1
  local dbname="$1" user pass
  local dir="$base_dir/mongodb/$dbname"
  local dump="$dir/$date"

  [[ "$dbname" =~ ^[A-Za-z0-9]+$ ]] || exit 1
  eval "user=\$mongo_auth__${dbname}__user"
  eval "pass=\$mongo_auth__${dbname}__pass"

  mkdir -p "$dir"
  echo "$pass" | run mongodump -h "$mongo_host" -d "$dbname" \
    -u "$user" -p '' -o "$dump"

  rm_obsolete_backups "$dir"
}                                                               # }}}1

# Usage: data_backup <dir>
# rsync directory to $base_dir/data/hash/$hash_of_dir, symlinked from
# $base_dir/data/path/$dir.
# Removes obsolete backups.
function data_backup ()
{                                                               # {{{1
  local data="$1"
  local hash="$( hashpath "$data" )"
  local ddir="$base_dir"/data
  local dir="$ddir/hash/$hash"
  local to="$dir/$date"

  mkdir -p "$dir"
  cp_last_backup "$dir" "$to"

  run rsync -a --delete "$data"/ "$to"/

  mkdir -p "$ddir/path/$( dirname "$data" )"
  [ -e "$ddir/path/$data" ] || run ln -Ts "$dir" "$ddir/path/$data"

  rm_obsolete_backups "$dir"
}                                                               # }}}1

# --

# 1. stop services
run_multi "${services_stop[@]}"

# 2. baktogit
[ "${#baktogit_items[@]}" -ne 0 ] && \
  run "$baktogit" "${baktogit_items[@]}"

# 3. postgresql
for info in "${postgresql_dbs[@]}"; do
  user="${info%%:*}" db="${info#*:}"
  pg_backup "$db" "${user:-$db}"
done

# 4. mongodb
[ "${#mongo_dbs[@]}" -ne 0 ] && process_mongo_passfile
for db in "${mongo_dbs[@]}"; do mongo_backup "$db"; done

# 5. data
for dir in "${data_dirs[@]}"; do data_backup "$dir"; done

# 6. start services
run_multi "${services_start[@]}"

# 7. copy backup to remote location(s)
# ... TODO ...

# vim: set tw=70 sw=2 sts=2 et fdm=marker :