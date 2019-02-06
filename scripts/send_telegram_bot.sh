#!/bin/sh
#===============================================================================
#
#        USAGE:  send-telegram-bot.sh < msg.txt
#
#  DESCRIPTION:  send text messages, documents and photos to telegram.                
#
# REQUIREMENTS:  curl
#        NOTES:  If you are interested in reading the output, I recommend 
#                it to jq
#       AUTHOR:  MulTux <https://github.com/multux>
#      CREATED:  01.02.2019
#     REVISION:  06.02.2019
#
#===============================================================================

#TG_API_TOKEN=''      # -a option I recommend to set the API Token per EV
CHAT_ID=''            # -c option
PARSE_MODE='HTML'     # -m option for Markdown
DOCUMENT=''           # -d option
PHOTO=''              # -p option
SILENT='false'        # -s option
RETRYS='20'

usage() {
  echo "
send-telegram-bot [options] < textfile

ENVIRONMENT VARIABLES
  TG_API_TOKEN from the BotFather (@TelegramBot)

Options:
  -a <apitoken>  -- API Token from the BotFather (@TelegramBot)
  -c <chatid>    -- defines the chatid
  -d <file>      -- attaches an document
  -h             -- shows this page
  -m             -- switch to markdown Mode
  -p <file>      -- attaches an photo
  -s             -- silent
  -u             -- makes an getUpdates request only

Examples:
  TG_API_TOKEN='<apitoken>' send_telegram_bot.sh -u
  echo \"Hello World\" | send_telegram_bot.sh -c <chatid>
  send_telegram_bot.sh -a <apitoken> -c <chatid> < textfile
  send_telegram_bot.sh -c <chatid> #End with STR+D

  send_telegram_bot.sh -c <chatid> -d <file> < caption
  send_telegram_bot.sh -c <chatid> -p <file> < caption
"
}

get_updates() {
  curl -X GET -s "${TG_ENDPOINT}/getUpdates"
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
  updates='false'

  while getopts "h?musa:c:d:p:" opt; do
    case "$opt" in
    h|\?) usage; exit 0 ;;
    a) TG_API_TOKEN=$OPTARG ;;
    c) CHAT_ID=$OPTARG ;;
    d) DOCUMENT=$OPTARG ;;
    m) PARSE_MODE='Markdown' ;;
    p) PHOTO=$OPTARG ;;
    s) SILENT='true' ;;
    u) updates='true' ;;
    esac
  done

  if [ ! "$TG_API_TOKEN" ]; then
    echo "TG_API_TOKEN is not set."
    exit 1
  fi

  TG_API='https://api.telegram.org'
  TG_ENDPOINT="${TG_API}/bot${TG_API_TOKEN}"

  if [ "$updates" = "true" ]; then
    get_updates
  elif [ -n "$DOCUMENT" ]; then
    run_command send_document
  elif [ -n "$PHOTO" ]; then
    run_command send_photo
  else
    run_command send_message
  fi
}

main "$@"