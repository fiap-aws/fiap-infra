data "aws_iam_policy_document" "fiap_devops_ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fiap_devops_ecs_node_role" {
  name_prefix        = "fiap-devops-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.fiap_devops_ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "fiap_devops_ecs_node_role_policy" {
  role       = aws_iam_role.fiap_devops_ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "fiap_devops_ecs_node" {
  name_prefix = "fiap-devops-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.fiap_devops_ecs_node_role.name
}