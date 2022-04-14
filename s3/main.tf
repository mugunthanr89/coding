provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "mybucket" {
  bucket = var.bucketname
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_sns_topic" "mytopic" {
  name = var.snsname
}

resource "aws_sns_topic_subscription" "mysubscription" {
  topic_arn = aws_sns_topic.mytopic.arn
  protocol  = "email"
  endpoint  = var.subsendpoint
}

resource "aws_sns_topic_policy" "snspolicy" {
  arn = aws_sns_topic.mytopic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_s3_bucket.mybucket.arn,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.mytopic.arn,
    ]

    sid = "__default_statement_ID"
  }
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.mybucket.id

  topic {
    topic_arn     = aws_sns_topic.mytopic.arn
    events        = ["s3:ObjectCreated:*"]
  }
}