# File Decompressor Script

## Purpose

This script is a Google Cloud Function designed to be triggered by changes in a Google Cloud Storage bucket. When a new file (expected to be a `.json.gz` file) is added to the source bucket, the function is triggered to:

1. Download and decompress the gzipped JSON file.
2. Upload the decompressed JSON file to a destination bucket.

This script was originally designed to consume archive log files that were sent to a Google Cloud Storage Bucket by DataDog's Log Archiving process, but can be used for other needs.

## How to Use

### Prerequisites

1. **Google Cloud Storage Buckets**: Create aGCS Bucket for the destination (where the decompressed files will be saved).
4. **Enable APIs**: Enable the Cloud Functions and Cloud Storage APIs for your project.
5. **Service Account**: Ensure the Cloud Function has the necessary permissions to read from the source bucket and write to the destination bucket.

### Deployment

1. **Update the Script**: Replace `<YOUR DESTINATION BUCKET NAME>` with the name of your destination bucket.
2. **Deploy the Function**:
    - Create a new function
    - Trigger type: `Cloud Storage`
    - Event Type: `google.cloud.storage.object.v1.finalized`
    - Bucket: source bucket that contains the compressed files
    - main.py: Copy code from `File_Decompressor.py`
    - requirements.txt
    ```
    functions-framework==3.*
    google-cloud-storage
    ```
