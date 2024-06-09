resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [aws_eks_cluster.apps_cluster]
}

resource "helm_release" "argocd" {
  name      = "argo-cd"
  chart     = "../../charts/argo-cd/"
  namespace = kubernetes_namespace.argocd.metadata.0.name

  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    kubernetes_namespace.argocd,
    aws_eks_node_group.apps_cluster_controller
  ]
}

resource "kubectl_manifest" "argocd_bootstrap" {
  yaml_body = file("../../argo-cd-applications/argo-bootstrap/argo-bootstrap.yaml")

  depends_on = [helm_release.argocd]
}
