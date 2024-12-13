#!/bin/bash

S3_BUCKET="noortestdata"
S3_PREFIX="m7ametal"
OUTPUT_FILE="frequency_data.csv"
SHOWBOOST_SCRIPT="showboost.sh"
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)


echo "Preparing CSV file..."
echo "Instance_Type,Load_Type,Time,CO_MCYC,CO_ACYC,UTIL,RATIO,MHz" > $OUTPUT_FILE


process_showboost_output() {
    local load_type=$1
    local output_file=$2
    awk -v type="$load_type" -v instance="$INSTANCE_TYPE" 'NR>5 {print instance","type","$0}' $output_file >> $OUTPUT_FILE
}

# Idle Load Test
echo "Running idle load test..."
sudo ./$SHOWBOOST_SCRIPT 5 12 > idle_output.txt
process_showboost_output "Idle" idle_output.txt

# Moderate Load Test: 96 Hogs
echo "Running moderate load test... 96 hogs"
sudo stress-ng --cpu 96 --timeout 60s &
sudo ./$SHOWBOOST_SCRIPT 5 12 > moderate_output.txt
process_showboost_output "Moderate" moderate_output.txt

# High Load Test: 192 Hogs
echo "Running high load test... 192 hogs"
sudo stress-ng --cpu 192 --timeout 60s &
sudo ./$SHOWBOOST_SCRIPT 5 12 > high_output.txt
process_showboost_output "High" high_output.txt

# Uploadong the results to S3
echo "Uploading results to S3..."
aws s3 cp $OUTPUT_FILE s3://$S3_BUCKET/$S3_PREFIX/$OUTPUT_FILE

echo "Results saved to S3: s3://$S3_BUCKET/$S3_PREFIX/$OUTPUT_FILE"
