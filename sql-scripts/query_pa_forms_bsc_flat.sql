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
  'beneficiaryAddress',
  'beneficiaryDoB',
  'beneficiaryLanguage',
  'beneficiaryName',
  'beneficiaryPhone',
  'beneficiaryPlanNumber',
  'beneficiaryState',
  'beneficiaryZip',
  'dateLastAuthorized',
  'diagCode',
  'diagDescription',
  'ipaResponsibility',
  'issurerName',
  'memberEffectiveDate',
  'modificationFax',
  'prevAuthNumber',
  'procCode',
  'procDesc',
  'referralRequestedBy',
  'retroFax',
  'routineFax',
  'rpFax',
  'rpJustification',
  'rpName',
  'rpNpi',
  'rpPhone',
  'rpSign',
  'rpSpecialty',
  'spAddress',
  'spFacilityName',
  'spFax1',
  'spFax2',
  'spName',
  'spNpi',
  'spPhone2',
  'spRequestDate',
  'urgentFax'
)) AS fields
Where document_class="pa_form_cda"