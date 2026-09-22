resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "terraform_state_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid = "AllowAreopagusStateList"

    principals {
      type = "AWS"
      identifiers = [
        local.areopagus_deployment_role_arn,
        local.areopagus_plan_role_arn,
      ]
    }

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.terraform_state.arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        var.areopagus_terraform_state_key,
        "${var.areopagus_terraform_state_key}.tflock",
      ]
    }
  }

  statement {
    sid = "AllowAreopagusStateReadWrite"

    principals {
      type = "AWS"
      identifiers = [local.areopagus_deployment_role_arn]
    }

    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.terraform_state.arn}/${var.areopagus_terraform_state_key}"]
  }

  statement {
    sid = "AllowAreopagusPlanStateRead"

    principals {
      type        = "AWS"
      identifiers = [local.areopagus_plan_role_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.terraform_state.arn}/${var.areopagus_terraform_state_key}"]
  }

  statement {
    sid = "AllowAreopagusTerraformLock"

    principals {
      type = "AWS"
      identifiers = [
        local.areopagus_deployment_role_arn,
        local.areopagus_plan_role_arn,
      ]
    }

    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.terraform_state.arn}/${var.areopagus_terraform_state_key}.tflock"]
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state_bucket.json
}
