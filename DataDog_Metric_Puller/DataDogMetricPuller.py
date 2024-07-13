import functions_framework
import json
import os
from datadog import initialize, api
from datetime import datetime, timedelta
from google.cloud import storage
from google.oauth2 import service_account

# For testing purposes, you can set the DEBUG environment variable here
#os.environ['DEBUG'] = 'true'

DEBUG = os.getenv('DEBUG', 'false').lower() == 'true'

def debug_print(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)

@functions_framework.cloud_event
def datadog_metrics_to_gcs(cloudevent):
    debug_print(f"Debugging is {'enabled' if DEBUG else 'disabled'}")
    debug_print("Initializing Datadog API client")
    
    # Initialize the Datadog client
    try:
        options = {
            'api_key': 'YOUR_DATADOG_API_KEY',
            'app_key': 'YOUR_DATADOG_APP_KEY',
            'api_host': 'https://api.us5.datadoghq.com'
        }
        initialize(**options)
    except Exception as e:
        debug_print(f"Error initializing Datadog client: {e}")
        return f"Error initializing Datadog client: {e}", 500

    try:
        # Set the time range for the previous day
        now = datetime.now()
        start_time = int((now - timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0).timestamp())
        end_time = int(now.replace(hour=0, minute=0, second=0, microsecond=0).timestamp())
        debug_print(f"Time range set from {start_time} to {end_time}")
    except Exception as e:
        debug_print(f"Error setting time range: {e}")
        return f"Error setting time range: {e}", 500

    # List of metrics to pull
    metrics = [
        {'query': 'avg:system.cpu.user{*}', 'descriptor': 'avg_cpu'},
        {'query': 'avg:system.mem.used{*}', 'descriptor': 'avg_mem'}
    ]

    for metric in metrics:
        query = metric['query']
        descriptor = metric['descriptor']
        try:
            debug_print(f"Querying Datadog for metric: {query}")
            results = api.Metric.query(start=start_time, end=end_time, query=query)

            # Print only the first set of characters of the results for debugging
            results_str = json.dumps(results)  # Convert results to string
            debug_print(f"Results for {descriptor}: {results_str[:1000]}")

            # Format the start and end times for the filename
            start_time_str = datetime.fromtimestamp(start_time).strftime('%Y%m%d%H%M%S')
            end_time_str = datetime.fromtimestamp(end_time).strftime('%Y%m%d%H%M%S')
            file_name = f'datadog_metrics_{descriptor}_{start_time_str}_to_{end_time_str}.json'

            # Save the results to a JSON file
            debug_print(f"Saving results to {file_name}")
            with open(file_name, 'w') as f:
                json.dump(results, f)
        except Exception as e:
            debug_print(f"Error querying Datadog API or saving results: {e}")
            return f"Error querying Datadog API or saving results: {e}", 500

        try:
            # Service account JSON content (replace with your actual service account JSON content)
            service_account_info = {
                "type": "service_account",
                "project_id": "YOUR_PROJECT_ID",
                "private_key_id": "YOUR_PRIVATE_KEY_ID",
                "private_key": "YOUR_PRIVATE_KEY",
                "client_email": "YOUR_CLIENT_EMAIL",
                "client_id": "YOUR_CLIENT_ID",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": "YOUR_CLIENT_X509_CERT_URL"
            }

            # Create credentials object from the service account info
            credentials = service_account.Credentials.from_service_account_info(service_account_info)
        except Exception as e:
            debug_print(f"Error creating credentials from service account info: {e}")
            return f"Error creating credentials from service account info: {e}", 500

        try:
            # Upload the file to Google Cloud Storage
            bucket_name = 'YOUR_BUCKET_NAME'
            destination_blob_name = f'datadog/metrics/{file_name}'

            debug_print(f"Connecting to GCS bucket: {bucket_name}")
            # Initialize a GCS client with the credentials
            storage_client = storage.Client(credentials=credentials)

            # Get the bucket and blob
            bucket = storage_client.bucket(bucket_name)
            blob = bucket.blob(destination_blob_name)

            debug_print(f"Uploading file {file_name} to bucket {bucket_name} at {destination_blob_name}")
            # Upload the file
            blob.upload_from_filename(file_name)

            print(f'File {file_name} uploaded to {destination_blob_name}.')
        except Exception as e:
            debug_print(f"Error uploading file to GCS: {e}")
            return f"Error uploading file to GCS: {e}", 500

    return "All files uploaded successfully.", 200
