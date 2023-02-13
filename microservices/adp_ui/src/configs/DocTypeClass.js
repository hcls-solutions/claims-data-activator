/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

// TODO dynamically generate docclasstype using JSON file
    // Try to get file from GCS: gs://${process.env.REACT_APP_CONFIG_BUCKET}/document_types_config.json
    // Fall back to the local file: config/document_types_config.json
    // See Python implementation in get_document_types_config() in common/config.py


    // new JSON to docclasstype mappings:
        // value:     document_types_config.key
        // doc_type:  doc_type   (but need to convert "supporting_documents"=> "Supporting Documents";  "application_form" => "Application Form"
        // doc_class: display_name

const docclasstype=[

// {
//     'value':'utility_bill',
//     'doc_type':'Supporting Documents',
//     'doc_class': 'Utility Bill'
// },
// {
//     'value':'unemployment_form',
//     'doc_type':'Application Form',
//     'doc_class': 'Unemployment Form'
// },
// {
//     'value':'claims_form',
//     'doc_type':'Supporting Documents',
//     'doc_class': 'Claims Form'
// },
{
    'value':'bsc_pa_form',
    'doc_type':'Supporting Documents',
    'doc_class': 'BSC Prior-Auth Form'
},
{
    'value':'generic_form',
    'doc_type':'Supporting Documents',
    'doc_class': 'Generic Form Parser'
},
// {
//     'value':'pay_stub',
//     'doc_type':'Supporting Documents',
//     'doc_class': 'Pay Stub'
// },
// {
//     'value':'driver_license',
//     'doc_type':'Supporting Documents',
//     'doc_class': 'Driver License'
// },
{
    'value':'prior_auth_form',
    'doc_type':'Supporting Documents',
    'doc_class': 'Prior-Authorization Texas Form'
},
]

// The New json FORMAT for each document_class
// {
//     "pay_stub": {
//         "doc_type":"supporting_documents",
//         "display_name": "Pay Stub",
//         "classifier_label": "pay_stub"
// },
//     "claims_form": {
//         "doc_type":"supporting_documents",
//         "display_name": "Claims Form",
//         "classifier_label": "claims_form",
//         "parser": "claims_form"
// },
//     "utility_bill": {
//         "doc_type":"supporting_documents",
//         "display_name": "Utility Bill",
//         "classifier_label": "utility_bill"
// },
//     "driver_license": {
//         "doc_type":"supporting_documents",
//         "doc_class": "Driver License",
//         "classifier_label": "DL",
//         "parser": "driver_license"
// },
//     "unemployment_form": {
//         "doc_type":"application_form",
//         "display_name": "Unemployment Form",
//         "classifier_label": "UE",
//         "parser": "unemployment_form"
// }
// }

'use strict';
const config = require('../config');
const {Storage} = require('@google-cloud/storage');

async function loadJsonConfig(bucketname, filename) {
    const file = await new Storage()
        .bucket(bucketname)
        .file(filename)
        .download();
    return JSON.parse(file[0].toString('utf8'));
}

const json = loadJsonConfig(config.get("CONFIG_BUCKET"), "document_types_config.json")

console.log(json);

const sorting=docclasstype.sort(function (a, b) {
    return a.doc_type.localeCompare(b.doc_type) || a.doc_class.localeCompare(b.doc_class);
});

console.log(sorting);

export default sorting;