
resource "random_id" "example" {
  byte_length = 8
}

resource "aws_s3_bucket" "example" {
  bucket = "cwang-${random_id.example.hex}"
}


resource "aws_s3_bucket" "log_bucket" {
  bucket = "cwang-${random_id.example.hex}-log-bucket"
}

resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.example.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "sample_data_csv" {
  bucket = aws_s3_bucket.example.id
  key    = "sample-data.csv"
  source = "sample-data.csv"
}


resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.example.json
}

data "aws_iam_policy_document" "example" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = ["vpce-1a2b3c4d"]
    }
  }
}
