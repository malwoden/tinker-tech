resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "tf_state" {
  #checkov:skip=CKV2_AWS_6:Public account block is at the account level
  #checkov:skip=CKV2_AWS_61:Object sizes will never justify the IA move
  #checkov:skip=CKV_AWS_144:Cross-region replication unecessary for this toy account
  bucket = "tinker-tech-apps-tf-state"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  #checkov:skip=CKV2_AWS_67:False Positive: https://github.com/bridgecrewio/checkov/issues/6294
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
