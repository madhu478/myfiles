resource "aws_launch_configuration" "autoscale_launch" {
  name = "webservers-asg"
  image_id = "ami-08e59b7cc4c18d10b"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.webservers.id}"]
  key_name = "docker"
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "autoscale_group" {
  launch_configuration = "${aws_launch_configuration.autoscale_launch.id}"
  vpc_zone_identifier = ["${aws_subnet.main1.id }","${ aws_subnet.main2.id} "]
#  load_balancers = ["${aws_elb.elb.name}"]
  min_size = 2
  max_size = 3
  tag {
    key = "Name"
    value = "autoscale"
    propagate_at_launch = true
  }
}



