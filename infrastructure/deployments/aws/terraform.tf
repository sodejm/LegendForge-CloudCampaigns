# =============================================================================
# AWS Backend Configuration — S3 + DynamoDB for Remote State
# =============================================================================

terraform {
  # Uncomment and fill in the S3 backend configuration after creating the S3 bucket
  # backend "s3" {
  #   bucket         = "your-foundry-terraform-state-bucket"
  #   key            = "aws/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "foundry-terraform-locks"
  # }

  # For now, use local state. Migrate to S3 backend after initial setup.
  # To migrate: run 'terraform init' after uncommenting the backend block above.

}

# ===== S3 Bucket for Terraform State (Optional: create outside Terraform first) =====
# Instructions:
# 1. Create manually: aws s3 mb s3://your-foundry-terraform-state-bucket --region us-east-1
# 2. Enable versioning: aws s3api put-bucket-versioning --bucket your-foundry-terraform-state-bucket --versioning-configuration Status=Enabled
# 3. Enable encryption: aws s3api put-bucket-encryption --bucket your-foundry-terraform-state-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
# 4. Block public access: aws s3api put-public-access-block --bucket your-foundry-terraform-state-bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
# 5. Uncomment the backend block above and run 'terraform init'

# ===== DynamoDB Table for Terraform Locks (Optional: create outside Terraform first) =====
# Instructions:
# 1. Create manually: aws dynamodb create-table --table-name foundry-terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region us-east-1
# 2. Add TTL: aws dynamodb update-time-to-live --table-name foundry-terraform-locks --time-to-live-specification AttributeName=Expires,Enabled=true --region us-east-1
