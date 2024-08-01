import os
import random
import string

from config import UPLOAD_URL
from fastapi import APIRouter
from common.utils.helper import split_uri_2_path_filename
from common.utils.logging_handler import Logger
from common.utils.iap import send_iap_request
from google.cloud import storage

logger = Logger.get_logger(__name__)
# API clients
gcs = None

MIME_TYPES = [
    "application/pdf",
    # "image/gif",  # TODO Add Support for all these types
    # "image/tiff",
    # "image/jpeg",
    # "image/png",
    # "image/bmp",
    # "image/webp"
]

START_PIPELINE_FILENAME = os.environ.get("START_PIPELINE_NAME",
                                         "START_PIPELINE")
router = APIRouter(prefix="/start-pipeline", tags=["Start Pipeline"])


storage_client = storage.Client()

CONTEXT = "california"


def upload_file(bucket_name, files, case_id):
  bucket = storage_client.get_bucket(bucket_name)

  letters = string.ascii_lowercase
  temp_folder = "".join(random.choice(letters) for i in range(10))
  if not os.path.exists(temp_folder):
    logger.info(f"Output directory used for extraction locally: {temp_folder}")
    os.mkdir(temp_folder)

  for file_uri in files:
    logger.info(f"file_uri={file_uri}")
    blob = bucket.blob(file_uri)
    prefix, file_name = split_uri_2_path_filename(file_uri)
    logger.info(f"file_name={file_name}")
    destination_file_name = os.path.join(temp_folder, file_name)
    logger.info(f"destination_file_name={destination_file_name}")
    blob.download_to_filename(destination_file_name)
    logger.info(f"Downloaded {file_uri} to  {destination_file_name}")
    files = {'file': (file_name, open(destination_file_name, 'rb'))}
    upload_task_url = f"{UPLOAD_URL}/upload_service/v1/upload_files?context={CONTEXT}&case_id={case_id}"
    process_task_response = send_iap_request(upload_task_url, method="POST", files=files)

    logger.info(f"response={process_task_response.text} with status code={process_task_response.status_code}")

