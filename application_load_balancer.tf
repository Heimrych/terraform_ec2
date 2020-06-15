resource "aws_alb" "alb_web" {
	name		=	"web-alb"
	internal	=	false
  load_balancer_type = "application"
	security_groups	=	[aws_security_group.alb-sg.id]
	subnets		=	[aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = var.default_tags
}

resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = aws_alb.alb_web.arn
  port              = 80 
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = aws_alb_target_group.alb_web_https.arn
    type             = "forward"  
  }
}

resource "aws_alb_target_group" "alb_web_https" {
	name	= "alb-web-https"
	vpc_id	= aws_vpc.vpc.id
	port	= 80
	protocol	= "HTTP"

  tags = var.default_tags
}

resource "aws_alb_target_group_attachment" "alb_nginx_http" {
  target_group_arn = aws_alb_target_group.alb_web_https.arn
  target_id        = aws_instance.nginx.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "alb_apache_http" {
  target_group_arn = aws_alb_target_group.alb_web_https.arn
  target_id        = aws_instance.apache.id
  port             = 80
}