#!/bin/bash

# Get current date and time formatted as yyyyMMdd-HHmmss
BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Check if JAR_COUNTER exists; if not, set it to 1
if [ -z "$JAR_COUNTER" ]; then
    JAR_COUNTER=1
else
    # Increment JAR_COUNTER
    JAR_COUNTER=$((JAR_COUNTER + 1))
fi

# Set the variables for the Azure pipeline
echo "##vso[task.setvariable variable=BUILD_TIMESTAMP]$BUILD_TIMESTAMP"
echo "##vso[task.setvariable variable=JAR_COUNTER]$JAR_COUNTER"

# Output for debugging purposes (can be removed later)
echo "BUILD_TIMESTAMP: $BUILD_TIMESTAMP"
echo "JAR_COUNTER: $JAR_COUNTER"
echo "BRANCH_NAME: $BRANCH_NAME"
echo "REPO_NAME: $REPO_NAME"
echo "BUILD_ID: $BUILD_ID"
echo "BUILD_NUMBER: $BUILD_NUMBER"

# Maven build command using the defined variables
mvn clean package \
    -DREPO_NAME="$REPO_NAME" \
    -DBRANCH_NAME="$BRANCH_NAME" \
    -DBUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
    -DBUILD_ID="$BUILD_ID" \
    -DBUILD_NUMBER="$BUILD_NUMBER" \
    -DJAR_COUNTER="$JAR_COUNTER"
