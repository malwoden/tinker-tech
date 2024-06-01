data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apps_cluster" {
  name               = "apps-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "apps_cluster_managed_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])
  policy_arn = each.key
  role       = aws_iam_role.apps_cluster.name
}

data "aws_iam_policy_document" "worker_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apps_cluster_worker" {
  name               = "apps-cluster-worker"
  assume_role_policy = data.aws_iam_policy_document.worker_assume_role.json
}

resource "aws_iam_role_policy_attachment" "apps_cluster_worker_managed_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  policy_arn = each.key
  role       = aws_iam_role.apps_cluster_worker.name
}

resource "aws_eks_cluster" "apps_cluster" {
  name     = "apps-cluster"
  role_arn = aws_iam_role.apps_cluster.arn
  version  = "1.30"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = values(module.vpc.private_subnet_ids)
  }

  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true

  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.apps_cluster_managed_policies
  ]
}

resource "aws_eks_node_group" "apps_cluster_controller" {
  cluster_name    = aws_eks_cluster.apps_cluster.name
  node_group_name = "apps-cluster-controller"
  node_role_arn   = aws_iam_role.apps_cluster_worker.arn
  subnet_ids      = values(module.vpc.private_subnet_ids)

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.apps_cluster_worker_managed_policies
  ]
}
