#!/bin/bash

# TODO: finish gpg/tar/sensitive data !!!
exit 1

# --                                                            ; {{{1
#
# File        : srvbak.bash
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-05-13
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# Usage       : srvbak.bash [ /path/to/srvbakrc ]
#
# --                                                            ; }}}1

set -e
export LC_COLLATE=C ; rc= date="$( date +'%FT%T' )" # no spaces!

# Usage: die <msg>
function die () { echo "$@" 2>&1; exit 1; }

# --

baktogit_items=() data_dir_n=0 sensitive_data_dir_n=0

function baktogit_items () { baktogit_items+=( "$@" ); }

function data_dir ()
{ eval 'data_dir__'"$data_dir_n"'=( "$@" )'; (( ++data_dir_n )); }

function sensitive_data_dir ()
{ eval 'sensitive_data_dir__'"$sensitive_data_dir_n"'=( "$@" )'
  (( ++sensitive_data_dir_n )); }

# --

for x in "$1" /etc/srvbakrc /opt/src/srvbak/srvbakrc; do
  [ -e "$x" ] && { rc="$x"; break; }
done

[ -z "$rc" ] && die 'no srvbakrc' ; source "$rc"
if [[ "$VERBOSE" == [Yy]* ]]; then verbose=-v; else verbose=; fi

# --

# Usage: run <cmd> <arg(s)>
function run () { echo "==> $@"; "$@"; echo; }

# Usage: run_multi <cmd1-with-args> <cmd2-with-args> ...
function run_multi () { local x; for x in "$@"; do run $x; done; }

# --

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
  local dir="$1" path="$2" ; local last="$( last_backup "$dir" )"
  [ -n "$last" -a -e "$dir/$last" ] && \
    run cp -alT "$dir/$last" "$path"
}                                                               # }}}1

# Usage: rm_obsolete_backups <dir>
# NB: call after new backup!
function rm_obsolete_backups ()
{                                                               # {{{1
  local dir="$1" x
  for x in $( obsolete_backups "$dir" ); do
    run echo rm -fr "$dir/$x"                                   # TODO
  done
}                                                               # }}}1

# --

# Usage: tar_gpg <file> <arg(s)>
# Uses $gpg_{opts,key}.
function tar_gpg ()
{
  local file="$1"; shift
  tar c "$@" | gpg "${gpg_opts[@]}" -e -r "$gpg_key" > "$file"
}

# --

# Usage: process_mongo_passfile
# Uses $mongo_passfile; sets $mongo_auth__${db}__{user,pass}.
function process_mongo_passfile ()
{                                                               # {{{1
  local oldifs="$IFS" db user pass ; IFS=:
  while read -r db user pass; do
    [[ "$db" =~ ^[A-Za-z0-9]+$ ]] || die 'invalid mongo db name'
    eval "mongo_auth__${db}__user=\$user"
    eval "mongo_auth__${db}__pass=\$pass"
  done < "$mongo_passfile" ; IFS="$oldifs"
}                                                               # }}}1

# --

# Usage: data_backup <dir> [<opt(s)>]
# rsync directory to $base_dir/data/hash/$hash_of_path/$date,
# symlinked from $base_dir/data/path/$dir.
# Hard links last backup (if any); removes obsolete backups.
function data_backup ()
{                                                               # {{{1
  local path="$1" ; shift ; local hash="$( hashpath "$path" )"
  local    ddir="$base_dir"/data
  local pdir_up="$ddir/path/$( dirname "$path" )"
  local    pdir="$ddir/path/$path"
  local    hdir="$ddir/hash/$hash"
  local      to="$hdir/$date"

  mkdir -p "$hdir"
  cp_last_backup "$hdir" "$to"
  run rsync -a $verbose --delete "$@" "$path"/ "$to"/
  mkdir -p "$pdir_up"
  [ -e "$pdir" ] || run ln -Ts "$hdir" "$pdir"
  rm_obsolete_backups "$hdir"
}                                                               # }}}1

# Usage: sensitive_data_backup <dir> [<opt(s)>]
# ...
function sensitive_data_backup ()
{
  ...
}

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

  [[ "$dbname" =~ ^[A-Za-z0-9]+$ ]] || die 'invalid mongo db name'
  eval "user=\$mongo_auth__${dbname}__user"
  eval "pass=\$mongo_auth__${dbname}__pass"

  mkdir -p "$dir"
  printf '%s\n' "$pass" | run mongodump -h "$mongo_host" \
    -d "$dbname" -u "$user" -p '' -o "$dump"
  rm_obsolete_backups "$dir"
}                                                               # }}}1

# --

echo "srvbak of $( hostname ) @ ${date/T/ }" ; echo

# 1. before
run_multi "${before[@]}"

# 2. baktogit
[ "${#baktogit_items[@]}" -ne 0 ] && \
  run "$baktogit" "${baktogit_items[@]}"

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

# 7. after
run_multi "${after[@]}"

echo

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
