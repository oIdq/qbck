#!/bin/bash

# disable inclusion of .DS_Store files in tar
COPYFILE_DISABLE=1

# check for QBCK_GCP_PREFIX
if [ -z ${QBCK_GCP_PREFIX+x} ]; then
  echo "\$QBCK_GCP_PREFIX must be specified"
  exit 2
fi
GCP_PREFIX=$QBCK_GCP_PREFIX

# basic function used for confirmation of actions
confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

usage_bck() {
  echo "qbck backup <file> [name]"
  exit 1
}

# do_bck <file> <name>
do_bck() {
  FILE="$1"
  NAME="$2"

  if [ $# -eq 1 ]; then
    if [ -z ${PREFIX+x} ]; then
      echo "PREFIX must be specified"
    fi
    NAME="${FILE#*$PREFIX/}"
  fi

  GCP_FILENAME="$GCP_PREFIX/$NAME"

  echo "Uploading '$FILE' as '$GCP_FILENAME'"
  confirm < /dev/tty || exit 1

  gpg -c -o- --batch --passphrase-file ~/.gcp-key.txt "$FILE" | pv -s $(($(du -sk "$FILE" | awk '{print $1}') * 1024)) | rclone rcat "$GCP_FILENAME"
  xattr -w user.has-remote-backup "1" "$FILE"
}

bck() {
  if [ $# -lt 2 ]; then
    usage_bck
  fi

  if [ $# -gt 4 ]; then
    usage_bck
  fi

  do_bck $2 $3
}

usage_sync() {
  echo "qbck sync <dir>"
  exit 1
}

sync() {
  if [ $# -ne 2 ]; then
    usage_sync
  fi

  DIR=$2
  PREFIX=$DIR

  find "$DIR" -type f -not -xattrname user.has-remote-backup -and -not -xattrname com.apple.FinderInfo -print0 | while read -d $'\0' file; do
    do_bck "$file"
  done

  echo "DONE"

}

usage_cmp() {
  echo "qbck compress <dir> <output_dir> [name]"
  exit 1
}

usage() {
  echo "qbck <command>"
  exit 1
}

cmp() {
  if [ $# -lt 3 ]; then
    usage_cmp
  fi

  if [ $# -gt 5 ]; then
    usage_cmp
  fi

  BCK_DIR=$2
  OUTPUT_DIR=$3
  _AUTO_NAME=$(basename -- "$BCK_DIR")
  NAME=${4:-$_AUTO_NAME}

  OUTPUT_FILENAME="$NAME.tar.gz"
  OUTPUT="$OUTPUT_DIR/$OUTPUT_FILENAME"
  TRANSFORM="s|$(basename $BCK_DIR)|$NAME|"

  echo "\n$BCK_DIR -> $OUTPUT\n(root directory of tar being $NAME/)\n"
  confirm || exit 1

  tar --transform=$TRANSFORM -cC "$(dirname $BCK_DIR)" "$(basename $BCK_DIR)" | pv -s $(($(du -sk $BCK_DIR | awk '{print $1}') * 1024)) | gzip > "$OUTPUT"
}

if [ $# -lt 1 ]; then
  usage
fi

case $1 in
"backup")
  bck "$@"
  ;;
"compress")
  cmp "$@"
  ;;
"sync")
  sync "$@"
  ;;
*)
  usage
  ;;

esac
