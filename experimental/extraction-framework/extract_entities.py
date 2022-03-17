"""
This is the main file for extraction framework, based on doc type specialized parser or
form parser functions will be called

"""

import json
import os
import re
import proto
import random
from google.cloud import documentai_v1 as documentai
from google.cloud import storage
from utils_functions import entities_extraction, download_pdf_gcs, extract_form_fields, del_gcs_folder, \
    form_parser_entities_mapping, extraction_accuracy_calc, clean_form_parser_keys
from config import *


def specialized_parser_extraction(parser_details: dict, gcs_doc_path: str, doc_type: str):
    """

    This is specialized parser extraction main function. It will send request to parser and retrieve response and call
        default and derived entities functions

    Parameters
    ----------
    parser_details: It has parser info like parser id, name, location, and etc
    gcs_doc_path: Document gcs path
    doc_type: Document type

    Returns: Specialized parser response - list of dicts having entity, value, confidence and manual_extraction information.
    -------
    """

    # The full resource name of the processor, e.g.:
    # projects/project-id/locations/location/processor/processor-id

    location = parser_details["location"]

    processor_id = parser_details["processor_id"]

    parser_name = parser_details["parser_name"]

    project_id = PROJECT_NAME

    opts = {}

    if location == "eu":
        opts = {"api_endpoint": "eu-documentai.googleapis.com"}

    client = documentai.DocumentProcessorServiceClient(client_options=opts)

    # parser api end point
    name = f"projects/{project_id}/locations/{location}/processors/{processor_id}"

    blob = download_pdf_gcs(
        gcs_uri=gcs_doc_path
    )

    document = {"content": blob.download_as_bytes(), "mime_type": "application/pdf"}

    # Configure the process request
    request = {"name": name, "raw_document": document}

    # send request to parser
    result = client.process_document(request=request)

    parser_doc_data = result.document

    # convert to json
    json_string = proto.Message.to_json(parser_doc_data)
    data = json.loads(json_string)

    # remove unnecessary entities from parser
    for each_attr in NOT_REQUIRED_ATTRIBUTES_FROM_SPECIALIZED_PARSER_RESPONSE:
        if "." in each_attr:
            parent_attr, child_attr = each_attr.split(".")

            for idx in range(len(data.get(parent_attr, 0))):
                data[parent_attr][idx].pop(child_attr, None)
        else:
            data.pop(each_attr, None)

    # this can be removed while integration
    # save parser op output
    with open("{}.json".format(os.path.join(parser_op, gcs_doc_path.split('/')[-1][:-4])), "w") as outfile:
        json.dump(data, outfile)

    required_entities = MAPPING_DICT[doc_type]

    # extract dl entities
    extracted_entity_dict = entities_extraction(data, required_entities, doc_type)

    # Create a list of entities dicts
    specialized_parser_entity_list = [v for k, v in extracted_entity_dict.items()]

    # this can be removed while integration
    # save extracted entities json
    with open("{}.json".format(os.path.join(extracted_entities, gcs_doc_path.split('/')[-1][:-4])), "w") as outfile:
        json.dump(specialized_parser_entity_list, outfile, indent=4)

    return specialized_parser_entity_list


def form_parser_extraction(parser_details: dict, gcs_doc_path: str, doc_type: str, state: str, timeout: int):

    """

    This is form parser extraction main function. It will send request to parser and retrieve response and call
        default and derived entities functions

    Parameters
    ----------
    parser_details: It has parser info like parser id, name, location, and etc
    gcs_doc_path: Document gcs path
    doc_type: Document Type
    state: State name
    timeout: Max time given for extraction entities using async form parser API

    Returns: Form parser response - list of dicts having entity, value, confidence and manual_extraction information.
    -------

    """

    location = parser_details["location"]
    processor_id = parser_details["processor_id"]
    parser_name = parser_details["parser_name"]

    # These variables will be removed later
    project_id = PROJECT_NAME  # later read this variable from project config files

    opts = {}

    # Location can be 'us' or 'eu'
    if location == "eu":
        opts = {"api_endpoint": "eu-documentai.googleapis.com"}

    client = documentai.DocumentProcessorServiceClient(client_options=opts)

    # create a temp folder to store parser op, delete folder once processing done
    # call create gcs bucket function to create bucket, folder will be created automatically not the bucket
    gcs_output_uri = GCS_OP_URI
    gcs_output_uri_prefix = FORM_PARSER_OP_TEMP_FOLDER

    # temp folder location
    destination_uri = f"{gcs_output_uri}/{gcs_output_uri_prefix}/"

    gcs_documents = documentai.GcsDocuments(
        documents=[{"gcs_uri": gcs_doc_path, "mime_type": "application/pdf"}]
    )

    input_config = documentai.BatchDocumentsInputConfig(gcs_documents=gcs_documents)

    # Temp op folder location
    output_config = documentai.DocumentOutputConfig(
        gcs_output_config={"gcs_uri": destination_uri}
    )

    # parser api end point
    name = f"projects/{project_id}/locations/{location}/processors/{processor_id}"

    # request for Doc AI
    request = documentai.types.document_processor_service.BatchProcessRequest(
        name=name, input_documents=input_config, document_output_config=output_config,
    )

    operation = client.batch_process_documents(request)

    # Wait for the operation to finish
    operation.result(timeout=timeout)

    # Results are written to GCS. Use a regex to find
    # output files
    match = re.match(r"gs://([^/]+)/(.+)", destination_uri)
    output_bucket = match.group(1)
    prefix = match.group(2)

    storage_client = storage.Client()
    bucket = storage_client.get_bucket(output_bucket)
    blob_list = list(bucket.list_blobs(prefix=prefix))

    extracted_entity_list = []

    form_parser_text = ""

    # saving form parser json, this can be removed from pipeline
    parser_json_folder = os.path.join(form_parser_raw_json_folder, gcs_doc_path.split("/")[-1][:-4])

    if not os.path.exists(parser_json_folder):
        os.mkdir(parser_json_folder)

    # browse through output jsons
    for i, blob in enumerate(blob_list):

        # If JSON file, download the contents of this blob as a bytes object.

        if ".json" in blob.name:

            blob_as_bytes = blob.download_as_bytes()

            # saving the parser response to the folder, remove this while integration
            parser_json_fname = os.path.join(parser_json_folder, 'res_{}.json'.format(i))
            with open(parser_json_fname, "wb") as file_obj:
                blob.download_to_file(file_obj)

            document = documentai.types.Document.from_json(blob_as_bytes)
            # print(f"Fetched file {i + 1}")

            form_parser_text += document.text

            # Read the text recognition output from the processor
            for page in document.pages:
                for form_field in page.form_fields:
                    field_name, field_name_confidence = extract_form_fields(form_field.field_name, document)
                    field_value, field_value_confidence = extract_form_fields(form_field.field_value, document)

                    # noise removal from keys
                    field_name = clean_form_parser_keys(field_name)

                    temp_dict = {"key": field_name, "value": field_value,
                                 "key_confidence": round(field_name_confidence, 2),
                                 "value_confidence": round(field_value_confidence, 2)}

                    extracted_entity_list.append(temp_dict)

            print("Extraction completed")

        else:
            print(f"Skipping non-supported file type {blob.name}")

    # delete temp folder
    del_gcs_folder(gcs_output_uri.split("//")[1], gcs_output_uri_prefix)

    # Save extracted entities json, can be removed from pipeline
    with open("{}.json".format(os.path.join(parser_op, gcs_doc_path.split('/')[-1][:-4])), "w") as outfile:
        json.dump(extracted_entity_list, outfile, indent=4)

    # mappping dictionary of document type and state
    mapping_dict = MAPPING_DICT[state]

    # Extract desired entites from form parser
    form_parser_entities_list = form_parser_entities_mapping(extracted_entity_list, mapping_dict, form_parser_text)

    # Save extract desired entities only
    with open("{}.json".format(os.path.join(extracted_entities, gcs_doc_path.split('/')[-1][:-4])), "w") as outfile:
        json.dump(form_parser_entities_list, outfile, indent=4)

    return form_parser_entities_list


def extract_entities(gcs_doc_path: str, doc_type: str, state: str):

    """

    This function calls specialed parser or form parser depends on document type

    Parameters
    ----------
    gcs_doc_path: Document gcs path
    doc_type: Type of documents. Ex: unemployment_form, driver_license, and etc
    state: state

    Returns
    -------
        List of dicts having entity, value, confidence and manual_extraction information.
        Extraction accuracy
    """

    parser_config_json = "parser_config.json"

    # read parser details from configuration json file
    with open(parser_config_json, 'r') as j:

        parsers_info = json.loads(j.read())
        parser_information = parsers_info.get(doc_type)

        # if parser present then do extraction else update the status
        if parser_information:
            parser_name = parser_information["parser_name"]
            if parser_name == "FormParser":
                desired_entities_list = form_parser_extraction(parser_information, gcs_doc_path, doc_type, state, 300)
            else:
                desired_entities_list = specialized_parser_extraction(parser_information, gcs_doc_path, doc_type)

            # extraction accuracy calculation
            document_extraction_confidence = extraction_accuracy_calc(desired_entities_list)
        else:
            # Parser not available
            print('parser not available for this document')

    return desired_entities_list, document_extraction_confidence


if __name__ == "__main__":

    # These variable are used for local env run. will be removed while integrating with API'S

    extracted_entities = "/home/venkatakrishna/Documents/Q/projects/doc-ai-test/application-arakansas/extracted-entities/without-noisy"

    parser_op = "/home/venkatakrishna/Documents/Q/projects/doc-ai-test/application-arakansas/async-parser-json/without-noisy"

    form_parser_raw_json_folder = "/home/venkatakrishna/Documents/Q/projects/doc-ai-test/application-arakansas/raw-json/without-noisy"

    gcs_doc_path = "gs://async_form_parser/input/arizona-driver-form-13.pdf"

    os.environ[
        'GOOGLE_APPLICATION_CREDENTIALS'] = "/home/venkatakrishna/Documents/Q/projects/doc-ai-test/claims-processing-dev-sa.json"

    # API Integration will start from here

    # Extract API Provides label and document
    doc_type = "driver_license"
    state = "arizona"
    gcs_doc_path = "gs://async_form_parser/input/arizona-driver-form-13.pdf"
    # gcs_doc_path = "gs://async_form_parser/input/Arkansas5.pdf"

    extract_entities(gcs_doc_path, doc_type, state)

    # use this code for looping in gcs folder, for bulk run

    """
    gcs_output_uri = "gs://async_form_parser"
    gcs_output_uri_prefix = "input"

    destination_uri = f"{gcs_output_uri}/{gcs_output_uri_prefix}/"

    match = re.match(r"gs://([^/]+)/(.+)", destination_uri)
    output_bucket = match.group(1)
    prefix = match.group(2)

    storage_client = storage.Client()
    bucket = storage_client.get_bucket(output_bucket)
    blob_list = list(bucket.list_blobs(prefix=prefix))

    for i, blob in enumerate(blob_list):
        if ".pdf" in blob.name:
            gcs_doc_path = gcs_output_uri + '/' + blob.name
            extract_entities(gcs_doc_path, doc_type, state)
    """