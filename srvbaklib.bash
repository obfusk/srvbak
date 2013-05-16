#!/bin/bash

# --                                                            ; {{{1
#
# File        : srvbaklib.bash
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-05-16
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --
#
# NB: set -e, umask 0077.
#
# Uses: $date, $verbose, $dryrun; $base_dir, $keep_last; $gpg_opts,
# $gpg_key; $mongo_host, $mongo_passfile.
#
# Uses/Sets: $BAKTOGIT_REPO, $baktogit_items, $baktogit_keep_last;
# $data_dir__${data_dir_n}, $data_dir_n;
# $sensitive_data_dir__${sensitive_data_dir_n}, $sensitive_data_dir_n.
#
# --                                                            ; }}}1

export LC_COLLATE=C

# --

# Usage: die <msg>
function die () { echo "$@" 2>&1; exit 1; }

# Usage: dryrun
# Uses: $dryrun.
function dryrun () { [[ "$dryrun" == [Yy]* ]]; }

function run_hdr () { echo "==> $@"; }
function run_ftr () { echo; }

# Usage: run <cmd> <arg(s)>
function run () { run_hdr "$@"; dryrun || "$@"; run_ftr; }

# Usage: run_multi <cmd1-with-args> <cmd2-with-args> ...
function run_multi () { local x; for x in "$@"; do run $x; done; }

# --

# Usage: baktogit_items <baktogit-arg(s)>
# Appends to $baktogit_items.
function baktogit_items () { baktogit_items+=( "$@" ); }

# Usage: data_dir <dir> [<arg(s)>]
# Sets $data_dir__${data_dir_n}, $data_dir_n.
function data_dir ()
{ eval 'data_dir__'"$data_dir_n"'=( "$@" )'; (( ++data_dir_n )); }

# Usage: sensitive_data_dir <dir> [<arg(s)>]
# Sets $sensitive_data_dir__${sensitive_data_dir_n},
# $sensitive_data_dir_n.
function sensitive_data_dir ()
{ eval 'sensitive_data_dir__'"$sensitive_data_dir_n"'=( "$@" )'
  (( ++sensitive_data_dir_n )); }

# --

# Usage: canonpath <path>
# No physical check on the filesystem, but a logical cleanup of a
# path.
# Uses perl.
function canonpath ()
{ perl -MFile::Spec -e 'print File::Spec->canonpath($ARGV[0])' "$1"; }

# Usage: hashpath <path>
# SHA1 hash of canonical path.
# Uses canonpath.
function hashpath ()
{ printf '%s' "$( canonpath "$1" )" | sha1sum | awk '{print $1}'; }

# --

# Usage: ls_backups <dir>
function ls_backups () { ls "$1" | grep -E '^[0-9]{4}-'; }

# Usage: last_backup <dir>
# Uses ls_backups.
function last_backup () { ls_backups "$1" | tail -n 1; }

# Usage: obsolete_backups <dir>
# Uses: $keep_last, ls_backups.
function obsolete_backups ()
{ ls_backups "$1" | head -n -"$keep_last"; }

# Usage: cp_last_backup <dir> <path>
# Copies last backup in <dir> (if one exists) to <path> using hard
# links.
# NB: call before new backup (or dir creation)!
# Uses last_backup.
function cp_last_backup ()
{                                                               # {{{1
  local dir="$1" path="$2" ; local last="$( last_backup "$dir" )"
  [ -n "$last" -a -e "$dir/$last" ] && \
    run cp -alT "$dir/$last" "$path"
}                                                               # }}}1

# Usage: rm_obsolete_backups <dir>
# NB: call after new backup!
# Uses $keep_last, obsolete_backups.
function rm_obsolete_backups ()
{                                                               # {{{1
  [ "$keep_last" == all ] && return
  local dir="$1" x
  for x in $( obsolete_backups "$dir" ); do
    run rm -fr "$dir/$x"
  done
}                                                               # }}}1

# --

# Usage: gpg_file <out> <in>
# Uses $gpg_{opts,key}.
function gpg_file ()                                            # {{{1
{
  local out="$1" in="$2"
  local gpg=( gpg "${gpg_opts[@]}" -e -r "$gpg_key" )

  run_hdr "${gpg[@]} < $in > $out"
  dryrun || "${gpg[@]}" < "$in" > "$out"
  run_ftr
}                                                               # }}}1

# Usage: tar_gpg <out> <arg(s)>
# Uses $gpg_{opts,key}.
function tar_gpg ()                                             # {{{1
{
  local out="$1" ; shift
  local tar=( tar c --anchored "$@" )
  local gpg=( gpg "${gpg_opts[@]}" -e -r "$gpg_key" )

  run_hdr "${tar[@]} | ${gpg[@]} > $out"
  dryrun || "${tar[@]}" | "${gpg[@]}" > "$out"
  run_ftr
}                                                               # }}}1

# --

# Usage: process_mongo_passfile
# Uses $mongo_passfile; sets $mongo_auth__${db}__{user,pass}.
function process_mongo_passfile ()
{                                                               # {{{1
  [ -e "$mongo_passfile" ] || \
    die "bad mongo_passfile: $mongo_passfile"

  local oldifs="$IFS" db user pass ; IFS=:
  while read -r db user pass; do
    [[ "$db" =~ ^[A-Za-z0-9]+$ ]] || die 'invalid mongo db name'
    eval "mongo_auth__${db}__user=\$user"
    eval "mongo_auth__${db}__pass=\$pass"
  done < "$mongo_passfile" ; IFS="$oldifs"
}                                                               # }}}1

# --

# Usage: baktogit_tar_gpg <baktogit> <baktogit-item(s)>
# baktogit --> tar + gpg to $base_dir/baktogit/$date.tar.gpg.
# Uses $BAKTOGIT_REPO, $baktogit_keep_last.
function baktogit_tar_gpg ()
{                                                               # {{{1
  local baktogit="$1" ; shift
  [ -x "$baktogit" -o -x "$( which "$baktogit" )" ] || \
    die "bad baktogit: $baktogit"

  local keep_last="$baktogit_keep_last"   # dynamic override
  local       dir="$base_dir/baktogit"
  local        to="$dir/$date".tar.gpg

  run "$baktogit" "$@"
  run mkdir -p "$dir"
  tar_gpg "$to" $verbose "$BAKTOGIT_REPO"
  rm_obsolete_backups "$dir"
}                                                               # }}}1

# Usage: data_backup <path> [<opt(s)>]
# rsync directory to $base_dir/data/hash/$hash_of_path/$date,
# symlinked from $base_dir/data/path/$path.
# Hard links last backup (if any); removes obsolete backups.
function data_backup ()
{                                                               # {{{1
  local path="$1" ; shift ; local hash="$( hashpath "$path" )"
  local    ddir="$base_dir"/data
  local pdir_up="$ddir/path/$( dirname "$path" )"
  local    pdir="$ddir/path/$path"
  local    hdir="$ddir/hash/$hash"
  local      to="$hdir/$date"

  run mkdir -p "$hdir" "$pdir_up"
  cp_last_backup "$hdir" "$to"
  run rsync -a $verbose --delete "$@" "$path"/ "$to"/
  [ -e "$pdir" ] || run ln -Ts "$hdir" "$pdir"
  rm_obsolete_backups "$hdir"
}                                                               # }}}1

# Usage: sensitive_data_backup <dir> [<opt(s)>]
# tar + gpg directory to
# $base_dir/sensitive_data/hash/$hash_of_path/$date.tar.gpg, symlinked
# from $base_dir/sensitive_data/path/$path.
# Removes obsolete backups.
function sensitive_data_backup ()
{                                                               # {{{1
  local path="$1" ; shift ; local hash="$( hashpath "$path" )"
  local    ddir="$base_dir"/sensitive_data
  local pdir_up="$ddir/path/$( dirname "$path" )"
  local    pdir="$ddir/path/$path"
  local    hdir="$ddir/hash/$hash"
  local      to="$hdir/$date".tar.gpg

  run mkdir -p "$hdir" "$pdir_up"
  tar_gpg "$to" $verbose "$@" "$path"
  [ -e "$pdir" ] || run ln -Ts "$hdir" "$pdir"
  rm_obsolete_backups "$hdir"
}                                                               # }}}1

# Usage: pg_backup <dbname> <dbuser>
# PostgreSQL dump to $base_dir/postgresql/$dbname/$date.sql.gpg.
# Removes obsolete backups.
# Uses $PG*.
function pg_backup ()
{                                                               # {{{1
  local dbname="$1" dbuser="$2"
  local dir="$base_dir/postgresql/$dbname"
  local temp="$( mktemp )"
  local dump="$dir/$date".sql.gpg

  run mkdir -p "$dir"
  run pg_dump "$dbname" -f "$temp" -w -U "$dbuser"
  gpg_file "$dump" "$temp"
  run rm -f "$temp"
  rm_obsolete_backups "$dir"
}                                                               # }}}1

# Usage: mongo_backup <dbname>
# MongoDB dump to $base_dir/mongodb/$dbname/$date.tar.gpg.
# Removes obsolete backups.
# Uses $mongo_{host,auth__${dbname}__{user,pass}}.
function mongo_backup ()
{                                                               # {{{1
  [ -n "$mongo_host" ] || die 'empty $mongo_host'

  local dbname="$1" user pass
  local dir="$base_dir/mongodb/$dbname"
  local temp="$( mktemp -d )" ; local tsub="$dbname/$date"
  local dump="$dir/$date".tar.gpg

  [[ "$dbname" =~ ^[A-Za-z0-9]+$ ]] || die 'invalid mongo db name'
  eval "user=\$mongo_auth__${dbname}__user"
  eval "pass=\$mongo_auth__${dbname}__pass"
  [ -n "$user" ] || die "empty \$mongo_auth__${dbname}__user"
  [ -n "$pass" ] || die "empty \$mongo_auth__${dbname}__pass"

  run mkdir -p "$dir" "$temp/$tsub"
  printf '%s\n' "$pass" | run mongodump -h "$mongo_host" \
    -d "$dbname" -u "$user" -p '' -o "$temp/$tsub"
  tar_gpg "$dump" $verbose -C "$temp" "$tsub"
  run rm -fr "$temp"
  rm_obsolete_backups "$dir"
}                                                               # }}}1

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
