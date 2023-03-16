connection: "healthcare-demo"

# include all the views
include: "/views/**/*.view"

datagroup: cas_dashboard_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: cas_dashboard_default_datagroup

explore: validation_table {}

explore: prior_auth_forms {}

explore: all_forms {}

explore: bsc_pa_form {}

explore: prior_auth_form {}

explore: bsc_pa_forms {}
