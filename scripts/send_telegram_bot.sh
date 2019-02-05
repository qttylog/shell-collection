#!/bin/sh
#===============================================================================
#
#        USAGE:  send-telegram-bot.sh < msg.txt
#
#  DESCRIPTION:  send text messages, documents and photos to telegram.
#                If you are interested in reading the output,
#                I recommend piping it to jq
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
RETRYS='20'

# Do not change!
TG_API='https://api.telegram.org/bot'
TG_ENDPOINT="${TG_API}/bot${API_TOKEN}"

usage() {
  echo "
send-telegram-bot [options] < stdin_text

Options:
  -a <apitoken>  -- API Token from the BotFather (@TelegramBot)
  -c <chatid>    -- defines the chatid
  -d <file>      -- attaches an document
  -h             -- shows this page
  -m             -- switch to markdown Mode
  -p <file>      -- either html or markdown
  -s             -- silent
  -u             -- makes an getUpdates request only"
}

get_updates() {
  curl -X GET "${TG_ENDPOINT}/getUpdates"
  echo ""
  exit $?
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

send_message() {
  curl -s \
     --retry "$RETRYS" \
     -X POST "${TG_ENDPOINT}/sendMessage" \
     -d chat_id="${CHAT_ID}" \
     -d parse_mode="${PARSE_MODE}" \
     -d text="${msg}"
}

send_document() {
  curl -s \
     --retry "$RETRYS" \
     -X POST "${TG_ENDPOINT}/sendDocument" \
     -F chat_id="${CHAT_ID}" \
     -F document=@"${DOCUMENT}" \
     -F parse_mode="${PARSE_MODE}" \
     -F caption="${msg}"
}

send_photo() {
  curl -s \
     --retry "$RETRYS" \
     -X POST "${TG_ENDPOINT}/sendPhoto" \
     -F chat_id="${CHAT_ID}" \
     -F photo=@"${PHOTO}" \
     -F parse_mode="${PARSE_MODE}" \
     -F caption="${msg}"
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
  elif [ -n "$PHOTO" ]; then
    run_command send_photo
  else
    run_command send_message
  fi
}

main "$@"