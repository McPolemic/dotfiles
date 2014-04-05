#!/bin/bash

URL="https://pfcu.slack.com/services/hooks/incoming-webhook?token=${SLACK_WEBHOOK_TOKEN}"
PAYLOAD="{'username': 'Dev-Watcher', \
          'text': '$1',              \
          'icon_url': 'https://avatars1.githubusercontent.com/u/1086321?s=140'}"
echo "Posting to ${URL}"
echo $PAYLOAD
curl -XPOST $URL -d $PAYLOAD
