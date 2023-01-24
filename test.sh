curl -X POST \
  -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @request.json \
  "https://us-documentai.googleapis.com/v1/projects/691579255811/locations/us/processors/79b2c1fa8b5b2e8a/processorVersions/pretrained-form-parser-v2.0-2022-11-10:batchProcess"

curl -X GET \
  -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
  -H "X-Goog-User-Project: prior-auth-poc" \
  "https://us-documentai.googleapis.com/v1/projects/691579255811/locations/us/operations/4795007697892427387" 

curl -X GET \
  -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
  -H "X-Goog-User-Project: prior-auth-poc" \
  "https://us-documentai.googleapis.com/v1/projects/691579255811/locations/us/operations/4910498771586317431" 