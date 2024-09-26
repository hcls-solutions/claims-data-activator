#!/usr/bin/env bash

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LOG="$DIR/deploy.log"
filename=$(basename $0)
timestamp=$(date +"%m-%d-%Y_%H:%M:%S")
echo "$timestamp - Running $filename ... " | tee "$LOG"

source "${DIR}"/SET

if [[ -z "${API_DOMAIN}" ]]; then
  echo API_DOMAIN env variable is not set.  | tee -a "$LOG"
  exit
fi

if [[ -z "${PROJECT_ID}" ]]; then
  echo PROJECT_ID variable is not set. | tee -a "$LOG"
  exit
fi

ENV="${ENV:-"dev"}"

echo "using ENV=$ENV" | tee -a "$LOG"

gcloud container clusters get-credentials main-cluster --region $REGION --project $PROJECT_ID


#Copy .env file to GCS for tracking changes
if [ -f "${DIR}/microservices/adp_ui/.env" ]; then
  gsutil cp "${DIR}/microservices/adp_ui/.env" "gs://${TF_VAR_config_bucket}/.env" | tee -a "$LOG"
else
    gsutil ls "gs://${TF_VAR_config_bucket}/.env" 2> /dev/null
    RETURN=$?
    if [[ $RETURN -gt 0 ]]; then
        echo "Error: .env file for adp_ui does not exist neither locally ${DIR}/microservices/adp_ui/.env nor in GCS gs://${TF_VAR_config_bucket}/.env"
        exit
    fi
  echo "Downloading gs://${TF_VAR_config_bucket}/.env file to  ${DIR}/microservices/adp_ui/.env (required locally for build)..."
  gsutil cp "gs://${TF_VAR_config_bucket}/.env" "${DIR}/microservices/adp_ui/.env"  | tee -a "$LOG"
fi


skaffold run -p "$ENV" | tee -a "$LOG"


timestamp=$(date +"%m-%d-%Y_%H:%M:%S")
echo "$timestamp Finished. Saved Log into $LOG"  | tee -a "$LOG"