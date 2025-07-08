project_id  = "ya-test-project-1-prod"
region      = "us-central1"
environment = "prod"

# Use environment variables for sensitive data
db_password = var.db_password  # Set via TF_VAR_db_password
api_key     = var.api_key      # Set via TF_VAR_api_key 