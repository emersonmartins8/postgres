#!/bin/bash

# Script runs the pgBackRest backup, reads back the status messages and posts the final results
# to slack.

# USAGE: pgBackRestToSlack.sh --stanza StanzaName --backupType full

function notify_slack
{
  # Update the Slack Channel and URL below to match your settings
  local slack_channel="#general"
  local slack_url="https://hooks.slack.com/services/Change-This-To-Your-URL"

  local alert_type="${1^^}"
  local escaped_message=$(printf "%s" "${2}" | sed 's/"/\\"/g' | sed "s/'/\\'/g" )
  local slack_color="#336699"

  case "$alert_type" in
    "ERROR")
      slack_color="#ff3300"
    ;;
    "WARNING")
      slack_color="#ff8000"
    ;;
    "SUCCESS")
      slack_color="#00b300"
    ;;
    "INFO")
      slack_color="#0080ff"
    ;;
    *)
      slack_color="#336699"
    ;;
  esac

  IFS='' read -r -d '' content <<-EOF
    "attachments": [
      {
        "mrkdwn_in": ["text", "fallback"],
        "fallback": "Backup for stanza: [${stanza}]: ${escaped_message}",
        "title": "Backup for stanza: [${stanza}]",
        "text": "${escaped_message}",
        "color": "$slack_color",
        "footer": "Source Time",
        "ts": "$(date +"%s")"
      }
    ]
EOF

  IFS='' read -r -d '' json_load <<-EOF
    {"channel": "$slack_channel",
      "mrkdwn": true,
      "username": "pgBackRest",
      ${content},
      "icon_emoji": ":pgbackrest:"
    }
EOF

  curl -s -d "payload=$json_load" $slack_url > /dev/null

}

# Stanza as defined in the pgbackrest.conf. Must be specified when script is called
stanza=""
# Backup type can be 'diff', 'incr' or 'full'. Default to 'incr'
backupType="incr"

while [ "$1" != "" ]; do
  case "$1" in
    --stanza)
      shift
      stanza="$1"
    ;;
    --backuptype)
      shift
      backupType="${1,,}"
    ;;
  esac
  shift
done

if [ -z "$stanza" ]; then
  notify_slack "ERROR" "Backup script called without ``stanza`` specified on the command line"
  exit 1
fi

if [ "$backupType" != "full" ] && [ "$backupType" != "incr" ] && [ "$backupType" != "diff" ]; then
  notify_slack "ERROR" "Incorrect ``backupType`` specified on the command line"
  exit 1
fi


# echo "Starting"

stdbuf -oL pgbackrest --stanza=$stanza --log-level-console=info --type=${backupType} backup 2>&1 | {

    while IFS= read -r line
    do
        if [[ "$line" == *"backup command end"* ]]; then
          backupEndStatus=$(printf "$line" | awk -F "end: " '{print $2} ')
        elif [[ "$line" == *"new backup label"* ]]; then
          backupLabel=$(printf "$line" | awk -F "label = " '{print $2} ')
        elif [[ "$line" == *"backup size"* ]]; then
          backupSize=$(printf "$line" | awk -F "INFO: " '{print $2} ')
        elif [[ "$line" == *"WARN"* ]]; then
          warningMessages+="$line"
        elif [[ "$line" == *"ERROR"* ]]; then
          errorMessages+="$line"
        fi
    done

   if [[ "$backupEndStatus" == *"success"* ]] && [ -z "$warningMessages"] && [ -z ${errorMessages} ]; then
    # echo "Backup Label: ${backupLabel}"
    # echo "$backupSize"
    # echo "Backup ${backupEndStatus}"
    alertType="SUCCESS"
    notificationMsg="\n *Backup Label:* ${backupLabel} \n ${backupSize}"
  elif [[ "$backupEndStatus" == *"success"* ]] && [ -n "$warningMessages" ]; then
    alertType="WARNING"
    notificationMsg="\n *Backup Label:* ${backupLabel} \n ${backupSize}"
    notificationMsg+="\n *Warnings* \n\n ${warningMessages} \n"
  else
    alertType="ERROR"

    if [ -n "$warningMessages" ]; then
      # printf "WARNINGS:\n%s\n" "$warningMessages"
      notificationMsg="\n *Warnings* \n\n ${warningMessages} \n"
    fi

    # printf "ERRORS:\n%s\n" "$errorMessages"
    notificationMsg+="\n *Errors* \n\n ${errorMessages} \n"
  fi

  # printf "Backup %s\n" "$backupEndStatus"

  notify_slack "$alertType" "Backup ${backupEndStatus} \n ${notificationMsg}"

  # echo "Finished"
}