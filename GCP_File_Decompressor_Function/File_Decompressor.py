import functions_framework
import gzip
import json
from google.cloud import storage
from google.cloud.exceptions import NotFound, Forbidden

# Triggered by a change in a storage bucket
@functions_framework.cloud_event
def process_file(cloud_event):
    try:
        event_data = cloud_event.data
        print(f"Received cloud event data: {json.dumps(event_data)}")

        # Extract the necessary details from the event data
        source_bucket_name = event_data.get("bucket")
        source_file_name = event_data.get("name")

        if not source_bucket_name or not source_file_name:
            raise KeyError("Missing required event data: 'bucket' or 'name'")

        destination_bucket_name = '<YOUR DESTINATION BUCKET NAME>'
        destination_file_name = source_file_name.replace('.json.gz', '.json')

        client = storage.Client()
        source_bucket = client.bucket(source_bucket_name)
        source_blob = source_bucket.blob(source_file_name)
        destination_bucket = client.bucket(destination_bucket_name)
        destination_blob = destination_bucket.blob(destination_file_name)

        print(f"Processing file: {source_file_name} from bucket: {source_bucket_name}")

        try:
            # Download and decompress the file
            with source_blob.open("rb") as gzipped_file:
                with gzip.GzipFile(fileobj=gzipped_file) as decompressed_file:
                    file_content = decompressed_file.read().decode('utf-8')
                    print(f"Decompressed file content: {file_content[:100]}...")  # Print first 100 characters for verification
        except NotFound:
            print(f"Error: File {source_file_name} not found in bucket {source_bucket_name}.")
            return
        except Forbidden:
            print(f"Error: Access to file {source_file_name} in bucket {source_bucket_name} is forbidden.")
            return
        except gzip.BadGzipFile:
            print(f"Error: File {source_file_name} is not a valid gzip file.")
            return
        except Exception as e:
            print(f"Error decompressing file {source_file_name}: {e}")
            return

        try:
            # Upload the decompressed file to the destination bucket
            destination_blob.upload_from_string(file_content, content_type='application/json')
            print(f"Processed {source_file_name} and saved as {destination_file_name}")
        except Exception as e:
            print(f"Error uploading file {destination_file_name} to bucket {destination_bucket_name}: {e}")

    except KeyError as e:
        print(f"KeyError: {e} - Event data received: {json.dumps(event_data)}")
    except Exception as e:
        print(f"Unexpected error processing file {source_file_name}: {e}")
        raise
