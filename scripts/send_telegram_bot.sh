#!/bin/sh
#===============================================================================
#
#        USAGE:  send-telegram-bot.sh < msg.txt
#
#  DESCRIPTION:  send text messages to telegram
#
# REQUIREMENTS:  curl
#       AUTHOR:  MulTux <https://github.com/multux>
#      CREATED:  01.02.2019
#     REVISION:  05.02.2019
#
#===============================================================================

API_TOKEN=''          # -a option
CHAT_ID=''            # -c option
PARSE_MODE='HTML'     # -m option for Markdown
DOCUMENT=''           # -d option
PHOTO=''              # -p option
SILENT='false'        # -s option

# Do not change!
T_API_URL='https://api.telegram.org/bot'
OPTIND=1 # reset

usage() {
  echo ""
  echo "send-telegram-bot [options] < stdin_text"
  echo ""
  echo "  OPTIONS"
  echo "  -a apitoken  -- API Token from the BotFather (@TelegramBot)"
  echo "  -c chatid    -- defines the chatid"
  echo "  -d document  -- attaches an document"
  echo "  -h           -- shows this page"
  echo "  -m           -- switch to markdown Mode"
  echo "  -p photo     -- either html or markdown"
  echo "  -s           -- silent"
  echo "  -u           -- makes an getUpdates request only"
  echo ""
}

get_updates() {
  curl -X GET "${T_API_URL}${API_TOKEN}/getUpdates"
  echo ""
  exit $?
}

send_message() {
  curl -s \
     --retry 20 \
     -X POST "${T_API_URL}${API_TOKEN}/sendMessage" \
     -d chat_id="${CHAT_ID}" \
     -d parse_mode="${PARSE_MODE}" \
     -d text="${msg}"
  echo ""
}

send_document() {
  curl -s \
     --retry 20 \
     -X POST "${T_API_URL}${API_TOKEN}/sendDocument" \
     -F chat_id="${CHAT_ID}" \
     -F document=@"${DOCUMENT}" \
     -F parse_mode="${PARSE_MODE}" \
     -F caption="${msg}"
  echo ""
}

send_photo() {
  curl -s \
     --retry 20 \
     -X POST "${T_API_URL}${API_TOKEN}/sendPhoto" \
     -F chat_id="${CHAT_ID}" \
     -F photo=@"${PHOTO}" \
     -F parse_mode="${PARSE_MODE}" \
     -F caption="${msg}"
  echo ""
}

run_command() {
  # read stdin
  msg=$(cat)

  if $SILENT; then
    $1 > /dev/null 2>&1
  else
    $1
  fi

  exit $?
}


main() {
  while getopts "h?musa:c:d:p:" opt; do
    case "$opt" in
    h|\?) usage; exit 0 ;;
    a) API_TOKEN=$OPTARG ;;
    c) CHAT_ID=$OPTARG ;;
    d) DOCUMENT=$OPTARG ;;
    m) PARSE_MODE='Markdown' ;;
    p) PHOTO=$OPTARG ;;
    s) SILENT='true' ;;
    u) get_updates ;;
    esac
  done

  if [ -n "$DOCUMENT" ]; then
    run_command send_document
    exit $?
  fi

  if [ -n "$PHOTO" ]; then
    run_command send_photo
    exit $?
  fi

  run_command send_message
}

main "$@"