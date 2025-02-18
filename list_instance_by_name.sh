#!/bin/bash

# Check if region parameter is provided
if [ -z "$1" ]; then
    echo "Error: Region parameter is required"
    exit 1
fi

# Set region from parameter
region=$1

# Check if JSON file exists
if [ ! -f "instance.json" ]; then
    echo "Error: instance.json file not found"
    exit 1
fi

# Function to start an instance
start_instance() {
    instance_name=$1
    # Get instance ID using the name tag
    instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" \
    --query 'Reservations[*].Instances[*].[InstanceId]' --output text --region "$region")
    
    if [ -z "$instance_id" ]; then
        echo "Error: Could not find instance with name: $instance_name"
        return 1
    fi
    
    aws ec2 start-instances --instance-ids "$instance_id" --region "$region"
    if [ $? -ne 0 ]; then
        echo "Failed to start instance: $instance_name (ID: $instance_id)"
        exit 1
    fi
    echo "starting instance: $instance_name"
}

# Function to stop an instance
stop_instance() {
    instance_name=$1
    # Get instance ID using the name tag
    instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" \
    --query 'Reservations[*].Instances[*].[InstanceId]' --output text --region "$region")
    
    if [ -z "$instance_id" ]; then
        echo "Error: Could not find instance with name: $instance_name"
        return 1
    fi
    
    aws ec2 stop-instances --instance-ids "$instance_id" --region "$region"
    if [ $? -ne 0 ]; then
        echo "Failed to stop instance: $instance_name (ID: $instance_id)"
        exit 1
    fi
    echo "stopping instance: $instance_name"
}

# Determine action based on time
current_hour=$(date +%H)
# starts the instances by 6am UTC
if [[ "$current_hour" -le "6" || "$current_hour" -gt "18" ]]; then
    echo "Starting instance...."
    jq -r '.[]' "instance.json" | while read instance; do
        start_instance "$instance"
    done
    echo "Starting instance completed"
else
    # stops the instances by 6pm UTC
    echo "Stopping instance...."
    jq -r '.[]' "instance.json" | while read instance; do
        stop_instance "$instance"
    done
    echo "Stopping instance completed"
fi