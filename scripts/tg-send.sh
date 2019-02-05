#!/bin/sh
#===============================================================================
#
#        USAGE:  tg-send.sh < msg.txt
#
#  DESCRIPTION:  send text messages to telegram
#
# REQUIREMENTS:  curl, jq
#       AUTHOR:  kmein <https://github.com/kmein>
#      CREATED:  01.02.2019
#     REVISION:  03.02.2019
#
#===============================================================================

PARSE_MODE='HTML' # -m option for Markdown
DOCUMENT='' # -d option
PHOTO='' # -p option
SILENT='false' # -s option
CHAT_ID=''

if [ ! "$TG_SEND_TOKEN" ]; then
  echo "TG_SEND_TOKEN is not set." >&1
  exit 1
fi


# Do not change!
TG_API='https://api.telegram.org'
TG_ENDPOINT="${TG_API}/bot${TG_SEND_TOKEN}"
OPTIND=1 # reset

#== FUNCTION ===================================================================
# DESCRIPTION:  shows help
#      RETURN:  none
usage() {
  cat <<EOF
tg-send [options] < FILE

Send stdin from a Telegram bot.

ENVIRONMENT VARIABLES
  TG_SEND_TOKEN  bot token (from @BotFather)

OPTIONS
  -c ID          set chat ID
  -d FILE        attach a document
  -h             show this help
  -m             send as Markdown (instead of HTML)
  -p FILE        attach a photo
  -s             don't log
  -u             request /getUpdates
EOF
}

#== FUNCTION ===================================================================
# DESCRIPTION:  getUpdates request
#      RETURN:  none
get_updates() {
  curl -s -X GET "${TG_ENDPOINT}/getUpdates" | jq
  exit $?
}

#== FUNCTION ===================================================================
# DESCRIPTION:  send messages
#   PARAMETER:  message text
#      RETURN:  none
send_message() {
  [ $# -lt 1 ] || exit 1

  curl -s \
     --retry 20 \
     -X POST "${TG_ENDPOINT}/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d parse_mode="$PARSE_MODE" \
     -d text="$1"
}

#== FUNCTION ===================================================================
# DESCRIPTION:  attach an document
#   PARAMETER:  document
#   PARAMETER:  caption (optional)
#      RETURN:  none
send_document() {
  [ $# -ge 1 ] || exit 1

  curl -s \
     --retry 20 \
     -X POST "${TG_ENDPOINT}/sendDocument" \
     -F chat_id="$CHAT_ID" \
     -F document=@"$1" \
     -F parse_mode="$PARSE_MODE" \
     -F caption="${2-}"
}

#== FUNCTION ===================================================================
# DESCRIPTION:  attach an photo
#   PARAMETER:  photo
#   PARAMETER:  caption (optional)
#      RETURN:  none
send_photo() {
  [ $# -ge 1 ] || exit 1

  curl -s \
     --retry 20 \
     -X POST "${TG_ENDPOINT}/sendPhoto" \
     -F chat_id="$CHAT_ID" \
     -F photo=@"$1" \
     -F parse_mode="$PARSE_MODE" \
     -F caption="${2-}"
}

#== FUNCTION ===================================================================
# DESCRIPTION:  takes a command as an argument and executes it
#      RETURN:  none

#== GETOPTS ====================================================================
while getopts "hmusc:d:p:" opt; do
  case "$opt" in
  h) usage && exit 0 ;;
  d) DOCUMENT=$OPTARG ;;
  m) PARSE_MODE='Markdown' ;;
  p) PHOTO=$OPTARG ;;
  s) SILENT='true' ;;
  c) CHAT_ID=$OPTARG ;;
  u) get_updates ;;
  *) usage && exit 0 ;;
  esac
done

#== MAIN =======================================================================
main() {
  if [ -f "$DOCUMENT" ]; then
    send_document "$DOCUMENT" "$(cat)"
  elif [ -f "$PHOTO" ]; then
    send_photo "$PHOTO" "$(cat)"
  else
    send_message "$(cat)"
  fi
}

if $SILENT; then
  main >/dev/null 2>&1
else
  main | jq
fi
