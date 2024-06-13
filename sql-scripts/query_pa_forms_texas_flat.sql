/* Copyright 2024 Google LLC
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*/

SELECT * FROM `.validation.entities`
                  PIVOT
                  (STRING_AGG(value, ",") as _,
                   STRING_AGG(corrected_value, ",") as corrected,
                   AVG(confidence) as conf
 FOR name IN (
    'clinicalReasonForUrgency',
    'genderFemale',
    'genderMale',
    'genderOther',
    'genderUnknown',
    'groupNumber',
    'issuerDate',
    'issuerFax',
    'issuerPhone',
    'memberID',
    'patientDoB',
    'patientName',
    'patientPhone',
    'pcpFax',
    'pcpName',
    'pcpPhone',
    'prevAuthNumber',
    'requestTypeExtension',
    'requestTypeInitial',
    'reviewTypeNonUrgent',
    'reviewTypeUrgent',
    'rpContactName',
    'rpContactPhone',
    'rpDate',
    'rpFax',
    'rpNPI',
    'rpName',
    'rpPhone',
    'rpSpecialty',
    'spFax',
    'spNPI',
    'spPhone',
    'spSpecialty',
    'subscriberName'
)) AS fields
Where document_class="pa_form_texas"