#!/bin/bash

# Check if region parameter is provided
if [ -z "$1" ]; then
    echo "Error: Region parameter is required"
    exit 1
fi

# Set region from parameter
REGION=$1
INSTANCE_STATE_FILE="/tmp/ec2_instances.txt" # Temporary file to store instance IDs

list_running_instances() {
  aws ec2 describe-instances \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text > "$INSTANCE_STATE_FILE"

  if [[ -s "$INSTANCE_STATE_FILE" ]]; then # Check if file is not empty
    echo "Running EC2 instances in region: $REGION"
    cat "$INSTANCE_STATE_FILE"
  else
    echo "No running EC2 instances found for  in region: $REGION."
  fi
}
start_instances() {
  if [[ -s "$INSTANCE_STATE_FILE" ]]; then
    instance_ids=$(cat "$INSTANCE_STATE_FILE")
    aws ec2 start-instances --instance-ids $instance_ids --region "$REGION"
    echo "Starting instances: $instance_ids"
  else
    echo "No instances to start (file is empty)."
  fi
}

stop_instances() {
  if [[ -s "$INSTANCE_STATE_FILE" ]]; then
      instance_ids=$(cat "$INSTANCE_STATE_FILE")
      aws ec2 stop-instances --instance-ids $instance_ids --region "$REGION"
      echo "Stopping instances: $instance_ids"
  else
      echo "No instances to stop (file is empty)."
  fi
}


# --- Main Logic ---

# Determine action based on time (example using hour)
current_hour=$(date +%H)

list_running_instances # Always list instances


if [[ "$current_hour" -ge "6" || "$current_hour" -lt "18" ]]; then
  echo "Starting instance...."
  start_instances
else
  echo "Stopping instance...."
  stop_instances
fi

rm -f "$INSTANCE_STATE_FILE" # Clean up temporary file