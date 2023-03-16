"""
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

"""
  User uploads apllication in the form of JSON data

"""
import requests
from endpoint_proxy import get_baseurl


def test_upload_json_data():
  """
   User uploads JSON application in json payload
  """
  upload_base_url = get_baseurl("upload-service")
  payload = {
    "case_id": "123A",
    "name": "William",
    "employer_name": "Quantiphi",
    "employer_phone_no": "9282112222",
    "context": "Callifornia",
    "dob": "7 Feb 1997",
    "document_type": "application_form",
    "document_class": "unemployment_form",
    "ssn": "1234567",
    "phone_no": "9730388333",
    "application_apply_date": "2022/03/16",
    "mailing_address": "Arizona USA",
    "mailing_city": "Phoniex",
    "mailing_zip": "123-33-22",
    "residential_address": "Phoniex , USA",
    "work_end_date": "2022/03",
    "sex": "Female"
  }
  response_app = requests.post(
    f"{upload_base_url}/upload_service/v1/upload_json",
    json =  payload)
  response_app.status_code = 200

