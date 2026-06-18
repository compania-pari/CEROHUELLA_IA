locals {
  tags = merge(
    {
      project     = "cerohuella-ia"
      environment = "shared"
      managedBy   = "terraform"
      repository  = "compania-pari/CEROHUELLA_IA"
      owner       = var.owner
      costCenter  = var.cost_center
      workload    = "shared-container-registry"
    },
    var.extra_tags
  )
}

