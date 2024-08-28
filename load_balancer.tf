data "aws_vpc" "default" {
    default = true
}

resource "aws_lb_target_group" "target-group" {
    health_check {
        interval            = 10
        path                = "/"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
    }

    name        = "lab-tg"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = "vpc-0173037fb39ba8aba"
}

resource "aws_lb" "application-lb" {
    name                = "lab-alb"
    internal            = false
    ip_address_type     = "ipv4"
    load_balancer_type  = "application"
    security_groups     = [aws_security_group.security_group.id]
    subnets = ["subnet-0192e8cf36b17d2d8", "subnet-0b1a20dd7cc7c2554"]

    tags = {
        Name = "lab-alb"
    }
}

resource "aws_lb_listener" "alb-listener" {
    load_balancer_arn       = aws_lb.application-lb.arn
    port                    = 80
    protocol                = "HTTP"
    default_action {
        target_group_arn    = aws_lb_target_group.target-group.arn
        type                = "forward"
    }
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
    count               = length(aws_instance.nodejs)
    target_group_arn    = aws_lb_target_group.target-group.arn
    target_id           = aws_instance.nodejs[count.index].id
}

output "elb-dns-name" {
    value = aws_lb.application-lb.dns_name
}