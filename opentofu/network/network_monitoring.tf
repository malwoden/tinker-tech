resource "aws_flow_log" "hub" {
  iam_role_arn    = aws_iam_role.hub_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.hub_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.hub.id
}

resource "aws_cloudwatch_log_group" "hub_flow_logs" {
  name              = "flow-logs/vpc/hub"
  retention_in_days = 365
}

data "aws_iam_policy_document" "hub_flow_logs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
      ]
    }
  }
}

resource "aws_iam_role" "hub_flow_logs" {
  name               = "flow-logs-hub"
  assume_role_policy = data.aws_iam_policy_document.hub_flow_logs_assume_role.json
}

data "aws_iam_policy_document" "hub_flow_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      aws_cloudwatch_log_group.hub_flow_logs.arn,
      "${aws_cloudwatch_log_group.hub_flow_logs.arn}*"
    ]
  }
}

resource "aws_iam_role_policy" "hub_flow_logs" {
  name   = "flow-logs-hub"
  role   = aws_iam_role.hub_flow_logs.id
  policy = data.aws_iam_policy_document.hub_flow_logs.json
}
