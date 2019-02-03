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
#     REVISION:  03.02.2019
#
#===============================================================================

API_TOKEN='' # -a option
CHAT_ID='' # -c option
PARSE_MODE='Markdown' # -p option Markdown or HTML
DOCUMENT='' # -d option
SILENT='false' # -s option

# Do not change!
T_API_URL='https://api.telegram.org/bot'
OPTIND=1 # reset

#== FUNCTION ===================================================================
# DESCRIPTION:  shows help
#      RETURN:  none
usage() {
  echo ""
  echo "send-telegram-bot [options] < stdin_text"
  echo ""
  echo "  OPTIONS"
  echo "  -a apitoken  -- API Token from the BotFather (@TelegramBot)"
  echo "  -c chatid    -- defines the chatid"
  echo "  -d document  -- attaches an document"
  echo "  -h           -- shows this page"
  echo "  -p pasemode  -- either html or markdown"
  echo "  -s           -- silent"
  echo "  -u           -- makes an getUpdates request only"
  echo ""
}

#== FUNCTION ===================================================================
# DESCRIPTION:  getUpdates request
#      RETURN:  none
get_updates() {
  curl -X GET "${T_API_URL}${API_TOKEN}/getUpdates"
  echo ""
  exit $?
}

#== FUNCTION ===================================================================
# DESCRIPTION:  attach an document
#      RETURN:  none
send_message() {
  curl -s \
     --retry 20 \
     -X POST "${T_API_URL}${API_TOKEN}/sendMessage" \
     -d chat_id="${CHAT_ID}" \
     -d parse_mode="${PARSE_MODE}" \
     -d text="${msg}"
  echo ""
}

#== FUNCTION ===================================================================
# DESCRIPTION:  attach an document
#      RETURN:  none
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

#== FUNCTION ===================================================================
# DESCRIPTION:  takes a command as an argument and executes it
#      RETURN:  none

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

#== GETOPTS ====================================================================
while getopts "h?usa:c:d:p:" opt; do
  case "$opt" in
  h|\?)
    usage
    exit 0
    ;;
  a)
    API_TOKEN=$OPTARG
    ;;
  c)
    CHAT_ID=$OPTARG
    ;;
  d)
    DOCUMENT=$OPTARG
    ;;
  p)
    PARSE_MODE=$OPTARG
    ;;
  s)
    SILENT='true'
    ;;
  u)
    get_updates
    ;;
  esac
done

#== MAIN =======================================================================
if [ -n "$DOCUMENT" ]; then
  run_command send_document
  exit $?
fi

run_command send_message