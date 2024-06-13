#!/usr/bin/env bash
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/../SET"
query=`cat $DIR/corrected_values.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.corrected_values


query=`cat $DIR/entities.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.entities

query=`cat $DIR/confidence.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.confidence

query=`cat $DIR/query_pa_forms_texas_flat.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.TEXAS_PA_FORMS

query=`cat $DIR/query_pa_forms_bsc_flat.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.BSC_PA_FORMS

query=`cat $DIR/bsc_pa_form.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.bsc_pa_form

query=`cat $DIR/prior_auth_texas_form.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.prior_auth_texas_form

query=`cat $DIR/all_forms.sql`
bq mk --use_legacy_sql=false --view "$query" \
--project_id $PROJECT_ID --dataset_id $BIGQUERY_DATASET $BIGQUERY_DATASET.all_forms
