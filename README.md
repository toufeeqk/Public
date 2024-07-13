# Datadog Metrics to GCS Script

## Purpose

This script is designed to pull specific metrics from the Datadog API, save the results to a JSON file, and upload these files to Google Cloud Storage (GCS). One JSON file will be stored per metric. The script is intended to run as a Google Cloud Function and can be triggered by Cloud Events such as Google Cloud Scheduler. The primary use case is to automate the process of collecting and storing Datadog metrics for further analysis or archival purposes. It is designed to pull metrics that you define for the previous day. Therefore the script can be executed any time the following day of the intended collection.

Although this has initially been designed to run as a Google Cloud Function, it can be adapted to run anywhere (ie. local, AWS Lambda, Azure Function)

## Prerequisites

1. Datadog API key and APP key
2. A Google Cloud Storage Bucket will be required. This is where JSON files containing the metric data will be placed. You will need to update the script below with the name of your bucket.
3. Create a service account key to be used if you don’t already have one. You will need the contents of the JSON file from the key creation process.
    - In Google cloud console, navigate to IAM & Admin
    - Select Service Accounts
    - Select account and create a new one if needed. Account will need read/write access to the Google Cloud Storage Bucket being used. 
    - Select the KEYS tab, 
    - Click ADD KEY
    - Create new key 
    - Select JSON
    - Click Create
    - Download the JSON file. You will copy and paste the contents into the script below.


## How to Use

1. **Set Up Environment Variables**:
   - `YOUR_DATADOG_API_KEY`: Your Datadog API key.
   - `YOUR_DATADOG_APP_KEY`: Your Datadog application key.
   - `YOUR_PROJECT_ID`: Your Google Cloud project ID.
   - `YOUR_PRIVATE_KEY_ID`: Your Google Cloud private key ID.
   - `YOUR_PRIVATE_KEY`: Your Google Cloud private key.
   - `YOUR_CLIENT_EMAIL`: Your Google Cloud client email.
   - `YOUR_CLIENT_ID`: Your Google Cloud client ID.
   - `YOUR_CLIENT_X509_CERT_URL`: Your Google Cloud client X509 certificate URL.
   - `YOUR_BUCKET_NAME`: The name of the Google Cloud Storage bucket where the files will be uploaded.

2. **Deploy the Cloud Function**:
    - Environment: 2nd gen
    - Trigger Type: Other trigger
        - Trigger type: Google sources
        - Cloud Scheduler
            - Event type: google.cloud.scheduler.v1.CloudScheduler.RunJob
    - Runtime environment variables
        - DEBUG: false *{set to true for debugging information sent to log}*
    - **main.py**: Copy code from DataDogMetricPuller.py
    - **requirements.txt**: Copy the code below
        ```
        functions-framework==3.*
        datadog
        google-cloud-storage
        google-auth
        google-auth-oauthlib
        google-auth-httplib2
        ```




3. **Triggering the Function**:
    - Create new Cloud Scheduler Job
    - Set frequency to once per day at a time of your choosing. For example the following cron schedule would run everyday at 15th hour (3 PM):
        ```
         0 15 * * *
    - Set time zone
    - Target type: Pub/Sub
    - Select the function in question
    - Message Body: enter a short description of the trigger