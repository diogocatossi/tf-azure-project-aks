#########################
# variable "terraform_remote_state_address" {
#   type = string
#   description = "Gitlab remote state file address"
  
# }

# variable "terraform_username" {
#   type = string
#   description = "Gitlab username to query remote state"
# }

# variable "terraform_access_token" {
#   type = string
#   description = "GitLab access token to query remote state"
# }

# variable "terraform_state_name" {
#     type = string
#     default = "default"
# }

variable "resource_group_prefix" {
  default       = "RG"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "az_location" {
  default = "eastus2"
  description   = "Location of the resource group."
}

###################################
# Tags
###################################

variable "tag_app" {
  type    = string
  default = "multi"
}

variable "tag_environment" {
  type    = string
  default = "homologation"
  validation {
    condition     = can(regex("^(^sandbox$)|(^development$)|(^homologation$)|(^production$){1}", var.tag_environment))
    error_message = "The environment value must be 'development' or 'homologation' or 'production'."
  }
}

variable "tag_product" {
  type    = string
  default = "multi"
}

variable "tag_squad" {
  type    = string
  default = "abn-innovation"
}

variable "tag_tier" {
  type    = string
  default = "multi"
}

