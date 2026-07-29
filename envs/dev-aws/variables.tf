variable "cidr_admin" {
  description = "CIDR autorisé pour le SSH (votre IP publique)."
  type        = string
  default     = "88.185.39.8/32"
}

variable "vpc_id" {
  description = "VPC existant à utiliser."
  type        = string
  default     = "vpc-0df3c05a870a5f9ec"
}

variable "subnet_id" {
  description = "Sous-réseau existant à utiliser."
  type        = string
  default     = "subnet-0e511e2830ea7a748"
}
