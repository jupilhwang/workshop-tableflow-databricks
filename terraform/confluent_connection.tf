locals {
  bedrock_ai_connection_endpoint = "https://bedrock-runtime.${var.cloud_region}.amazonaws.com/model/${var.aws_bedrock_anthropic_model_id}/invoke"
}

# Due to resource limits with AWS Workshop Studio accounts in that Bedrock is only available
# in us-east-1 and us-west-2, we'll omit using this for the hands-on workkshop and add it back in later
# TODO: Add back in later

# Due to resource limits with AWS Workshop Studio accounts in that Bedrock is only available
# in us-east-1 and us-west-2, we'll omit using this for the hands-on workkshop and add it back in later
# TODO: Add back in later

resource "confluent_flink_connection" "bedrock_ai_connection" {
  organization {
    id = data.confluent_organization.current.id
  }
  environment {
    id = confluent_environment.staging.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.flink-compute-pool.id
  }
  principal {
    id = confluent_service_account.app-manager.id
  }
  rest_endpoint = data.confluent_flink_region.demo_flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  display_name      = "bedrock-claude-connection"
  type              = "BEDROCK"
  endpoint          = local.bedrock_ai_connection_endpoint
  aws_access_key    = var.aws_access_key_id
  aws_secret_key    = var.aws_secret_access_key
  # aws_session_token = var.aws_session_token
}