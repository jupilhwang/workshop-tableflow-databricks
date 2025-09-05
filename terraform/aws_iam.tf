# -------------------------------
# IAM Role for both S3 Access (Tableflow) and Databricks
# -------------------------------

# Local variable for the IAM role name
locals {
  # iam_role_name   = "${local.prefix}-unified-role-${random_id.env_display_id.hex}"
  iam_tableflow_role_name = "${local.prefix}-tableflow-role-${random_id.env_display_id.hex}"
  iam_databricks_role_name = "${local.prefix}-databricks-role-${random_id.env_display_id.hex}"
}

# --- IAM Role Definition ---
# https://docs.confluent.io/cloud/current/connectors/provider-integration/index.html
resource "aws_iam_role" "s3_access_role_tableflow" {
  name        = local.iam_tableflow_role_name
  description = "IAM role for accessing S3 with trust policies for Confluent Tableflow and Databricks Unity Catalog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    # Statement = [
      # # Statement 1 (Confluent): Allow Confluent Provider Integration Role to Assume this role
      # {
      #   Effect = "Allow"
      #   Principal = {
      #     AWS = confluent_provider_integration.s3_tableflow_integration.aws[0].iam_role_arn
      #   }
      #   Action = "sts:AssumeRole"
      #   Condition = {
      #     StringEquals = {
      #       "sts:ExternalId" = confluent_provider_integration.s3_tableflow_integration.aws[0].external_id
      #     }
      #   }
      # },
      # # Statement 2 (Confluent): Allow Confluent Provider Integration Role to Tag Session
      # {
      #   Effect = "Allow"
      #   Principal = {
      #     AWS = confluent_provider_integration.s3_tableflow_integration.aws[0].iam_role_arn
      #   }
      #   Action = "sts:TagSession"
      # }
    # ]
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action = "sts:AssumeRole"  
      }
    ]
  })
}

# Attaching the AWS managed S3 full access policy for the demo
resource "aws_iam_role_policy_attachment" "s3_policy_attachment_tableflow" {
  role       = aws_iam_role.s3_access_role_tableflow.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "null_resource" "wait_for_confluent_provider_integration_propagation" {
    provisioner "local-exec" {
    command = "sleep 30"
  }

  depends_on = [
    confluent_provider_integration.s3_tableflow_integration
  ]
}

resource "null_resource" "update_iam_role_trust_policy_tableflow" {
  # LESSON LEARNED: Update trust policy with actual external ID from provider integration
  # This is the key to making Tableflow work properly

  provisioner "local-exec" {
    command = <<-EOT
      aws iam update-assume-role-policy \
        --role-name ${aws_iam_role.s3_access_role_tableflow.name} \
        --policy-document '{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": "sts:AssumeRole",
              "Principal": {
                "AWS": "${confluent_provider_integration.s3_tableflow_integration.aws[0].iam_role_arn}"
              },
              "Condition": {
                "StringEquals": {
                  "sts:ExternalId": "${confluent_provider_integration.s3_tableflow_integration.aws[0].external_id}"
                }
              }
            },
            {
              "Effect": "Allow",
              "Action": "sts:TagSession",
              "Principal": {
                "AWS": "${confluent_provider_integration.s3_tableflow_integration.aws[0].iam_role_arn}"
              }
            }
          ]
        }'
    EOT
  }

  depends_on = [
    null_resource.wait_for_confluent_provider_integration_propagation
  ]

  triggers = {
    provider_integration_id = confluent_provider_integration.s3_tableflow_integration.id
    role_arn                = aws_iam_role.s3_access_role_tableflow.arn
  }
}


## -------------------------------
# IAM Role for Databricks Unity Catalog S3 Access
# ------------------------------- 
resource "aws_iam_role" "s3_access_role_databricks" {
  name        = local.iam_databricks_role_name
  description = "IAM role for accessing S3 with trust policies for Confluent Tableflow and Databricks Unity Catalog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
     Statement = [
      # Statement 3 (Databricks): Trust relationship for Databricks Root Account (from working example)
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.databricks_account_id
          }
        }
      }
    ]
  })

  # LESSON LEARNED: Use lifecycle to ignore changes to trust policy
  # This prevents Terraform from reverting our programmatic updates
  lifecycle {
    ignore_changes = [assume_role_policy]
  }

  tags = merge(local.common_tags, {
    Name = local.iam_databricks_role_name
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment_databricks" {
  role       = aws_iam_role.s3_access_role_databricks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# ===============================
# Update IAM Role Trust Policy with Real External ID
# ===============================
resource "null_resource" "update_iam_role_trust_policy_databricks" {
  # LESSON LEARNED: Update trust policy with actual external ID from storage credential
  # This is the key to making Unity Catalog work properly
  # CRITICAL: Unity Catalog requires BOTH Databricks access AND self-assumption capability

  provisioner "local-exec" {
    command = <<-EOT
      aws iam update-assume-role-policy \
        --role-name ${aws_iam_role.s3_access_role_databricks.name} \
        --policy-document '{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": "sts:AssumeRole",
              "Principal": {
                "AWS": "arn:aws:iam::414351767826:root"
              },
              "Condition": {
                "StringEquals": {
                  "sts:ExternalId": "${databricks_storage_credential.external_credential.aws_iam_role[0].external_id}"
                }
              }
            },
            {
              "Effect": "Allow",
              "Action": "sts:AssumeRole",
              "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
            }
          ]
        }'
    EOT
  }

  depends_on = [
    databricks_storage_credential.external_credential
  ]

  triggers = {
    storage_credential_id = databricks_storage_credential.external_credential.id
    role_arn              = aws_iam_role.s3_access_role_databricks.arn
  }
}

# ===============================
# Wait for Trust Policy Propagation
# ===============================

resource "null_resource" "wait_for_trust_policy_databricks_propagation" {
  # LESSON LEARNED: AWS IAM changes need time to propagate
  # Extended delay to ensure role is fully available before self-reference
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [
    null_resource.update_iam_role_trust_policy_databricks
  ]
}

# ===============================
# Update IAM Role Trust Policy with Specific Role ARN for Self-Assumption
# ===============================

resource "null_resource" "update_iam_role_trust_policy_databricks_final" {
  # LESSON LEARNED: Unity Catalog requires specific role ARN for self-assumption
  # This second update replaces account root with specific role ARN
  # CRITICAL: Must wait for role to be fully propagated before self-reference

  provisioner "local-exec" {
    command = <<-EOT
      aws iam update-assume-role-policy \
        --role-name ${aws_iam_role.s3_access_role_databricks.name} \
        --policy-document '{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": "sts:AssumeRole",
              "Principal": {
                "AWS": "arn:aws:iam::414351767826:root"
              },
              "Condition": {
                "StringEquals": {
                  "sts:ExternalId": "${databricks_storage_credential.external_credential.aws_iam_role[0].external_id}"
                }
              }
            },
            {
              "Effect": "Allow",
              "Action": "sts:AssumeRole",
              "Principal": {
                "AWS": "${aws_iam_role.s3_access_role_databricks.arn}"
              }
            }
          ]
        }'
    EOT
  }

  depends_on = [
    null_resource.wait_for_trust_policy_databricks_propagation,
    databricks_storage_credential.external_credential
  ]

  triggers = {
    storage_credential_id = databricks_storage_credential.external_credential.id
    role_arn              = aws_iam_role.s3_access_role_databricks.arn
    step                  = "final_specific_role_arn"
  }
}

# ===============================
# Wait for Final Trust Policy Propagation
# ===============================

resource "null_resource" "wait_for_final_trust_policy_databricks_propagation" {
  # LESSON LEARNED: AWS IAM changes need time to propagate
  provisioner "local-exec" {
    command = "sleep 30"
  }

  depends_on = [
    null_resource.update_iam_role_trust_policy_databricks_final
  ]
}



output "aws_iam" {
  value = {
    role_arn         = aws_iam_role.s3_access_role_tableflow.arn
    role_name        = aws_iam_role.s3_access_role_tableflow.name
    role_id          = aws_iam_role.s3_access_role_tableflow.id
    # role_policy_name = aws_iam_role_policy.s3_access_policy_tableflow.name
    # role_policy_id   = aws_iam_role_policy.s3_access_policy_tableflow.id
  }
}
