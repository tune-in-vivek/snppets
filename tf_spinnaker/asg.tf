resource "aws_alb" "spinnaker" {
  name_prefix     = "spinna"
  subnets         = ["${var.public_subnets}"]
  security_groups = ["${aws_security_group.alb.id}"]
}

resource "aws_alb_listener" "spinnaker" {
  load_balancer_arn = "${aws_alb.spinnaker.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${var.cert_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.spinnaker.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_certificate" "additional" {
  count           = "${length(var.additional_cert_arns)}"
  certificate_arn = "${element(var.additional_cert_arns, count.index)}"
  listener_arn    = "${aws_alb_listener.spinnaker.arn}"
}

resource "aws_alb_target_group" "spinnaker" {
  name     = "spinnaker-target"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_launch_configuration" "spinnaker" {
  name_prefix          = "${local.product_id}-"
  image_id             = "${data.aws_ami.spinnaker.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${module.iam.instance}"

  user_data = <<EOF
export CLOUD_ENVIRONMENT=${var.environment}
export CLOUD_APP=${var.product}
export CLOUD_APP_GROUP=${var.product}
export CLOUD_STACK=${var.environment}
export EC2_REGION=${data.aws_region.current.name}
export HOSTED_ZONE=""
export CHEF_ENVIRONMENT=${var.chef_environment}
EOF

  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.app.id}", "${var.additional_security_groups}"]

  root_block_device {
    volume_size = "50"
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "spinnaker" {
  desired_capacity     = "${var.desired_capacity}"
  health_check_type    = "EC2"
  launch_configuration = "${aws_launch_configuration.spinnaker.name}"
  max_size             = "${var.max_size}"
  min_size             = "${var.min_size}"
  name_prefix          = "${local.product_id}-"
  vpc_zone_identifier  = ["${var.private_subnets}"]
  availability_zones   = "${var.availability_zones}"

  tag {
    key                 = "Name"
    value               = "${local.product_id}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "spinnaker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Product"
    value               = "${var.product}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "spinnaker" {
  autoscaling_group_name = "${aws_autoscaling_group.spinnaker.id}"
  alb_target_group_arn   = "${aws_alb_target_group.spinnaker.arn}"
}