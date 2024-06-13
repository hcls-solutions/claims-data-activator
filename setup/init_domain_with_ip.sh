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

LOG="$DIR/init_domain.log"

timestamp=$(date +"%m-%d-%Y_%H:%M:%S")
echo "$timestamp - Running init_domain_with_ip.sh  ... " | tee "$LOG"

source "${DIR}"/SET  | tee -a "$LOG"

gcloud container clusters get-credentials main-cluster --region $REGION --project $PROJECT_ID

export TF_VAR_admin_email=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

export API_DOMAIN=$(kubectl describe ingress default-ingress | grep Address | awk '{print $2}')
export TF_VAR_api_domain=$API_DOMAIN

echo "Using IP address = $TF_VAR_api_domain"  | tee -a "$LOG"
cd terraform/stages/foundation || exit
terraform apply -target=module.ingress -target=module.cloudrun-queue -target=module.cloudrun-start-pipeline -auto-approve  | tee -a "$LOG"
cd ../../../
timestamp=$(date +"%m-%d-%Y_%H:%M:%S")
echo "$timestamp Finished. Saved Log into $LOG" | tee -a "$LOG"
