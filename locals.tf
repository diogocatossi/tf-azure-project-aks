locals {
    common_tags = {
        App         = var.tag_app
        Environment = var.tag_environment
        Product     = var.tag_product
        Squad       = var.tag_squad
        Tier        = var.tag_tier
    }

    appgwyname = "appgwy-aks-ingress"
    

}
