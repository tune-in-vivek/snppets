locals {
  iam_path = "/${data.aws_region.current.name}/${var.product}/${var.environment}/"
}

module "iam" {
  source      = "<github-repo>//iam"
  name_prefix = "spinnaker-"
  product     = "${var.product}"
  environment = "${var.environment}"
  pass_role   = "1"
  rw_buckets  = ["${aws_s3_bucket.bucket.arn}"]
}

data "aws_iam_policy_document" "spinnaker_poweruser" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "autoscaling:*",
      "ec2:*",
      "s3:*",
      "cloudwatch:*",
      "elasticloadbalancing:*",
      "sts:*",
    ]
  }
}

resource "aws_iam_role_policy" "spinnaker-poweruser" {
  name   = "powerusers-spinnaker"
  policy = "${data.aws_iam_policy_document.spinnaker_poweruser.json}"
  role   = "${module.iam.role}"
}