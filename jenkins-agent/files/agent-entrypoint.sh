#!/bin/sh

echo "Waiting for Jenkins to become healthy..."

until curl -sf "$JENKINS_URL/whoAmI/api/json?tree=authenticated" | grep -q '"authenticated":true'; do
  echo "Jenkins is not ready yet... waiting"
  sleep 5
done

echo "Jenkins is ready. Starting agent..."

SECRET_FILE=~/.jenkins/$JENKINS_AGENT_NAME.secret
# Wait for the controller to write the secret
while [ ! -s "$SECRET_FILE" ]; do
  echo "Waiting for agent secret..."
  sleep 2
done
export JENKINS_SECRET="$(cat "$SECRET_FILE")"
exec jenkins-agent
