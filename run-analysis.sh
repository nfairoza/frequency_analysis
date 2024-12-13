#!/bin/bash

#
S3_BUCKET="noortestdata"
S3_PREFIX="m7ametal"
OUTPUT_FILE="${S3_PREFIX}_frequency_data.csv"
SHOWBOOST_SCRIPT="showboost.sh"



echo "Preparing CSV file..."
echo "Instance_Type,Load_Type,Time,CO_MCYC,CO_ACYC,UTIL,RATIO,MHz" > $OUTPUT_FILE


process_showboost_output() {
    local load_type=$1
    local output_file=$2
    awk -v type="$load_type" -v instance="$S3_PREFIX" \
        'NR>7 {print instance","type","$1","$2","$3","$4","$5","$6}' \
        $output_file >> $OUTPUT_FILE
}


echo "Running idle load test..."
sudo ./$SHOWBOOST_SCRIPT 5 12 > idle_output.txt
process_showboost_output "Idle" idle_output.txt


echo "Running moderate load test..."
sudo stress-ng --cpu 96 --timeout 60s &
sudo ./$SHOWBOOST_SCRIPT 5 12 > moderate_output.txt
process_showboost_output "Moderate" moderate_output.txt


echo "Running high load test..."
sudo stress-ng --cpu 192 --timeout 60s &
sudo ./$SHOWBOOST_SCRIPT 5 12 > high_output.txt
process_showboost_output "High" high_output.txt


echo "Uploading results to S3..."
aws s3 cp $OUTPUT_FILE s3://$S3_BUCKET/$S3_PREFIX/$OUTPUT_FILE

echo " Results saved to S3: s3://$S3_BUCKET/$S3_PREFIX/$OUTPUT_FILE"
