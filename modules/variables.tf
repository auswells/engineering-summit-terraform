variable "gcp_project" { type = string }

variable "cluster_name" { type = string }

variable "gcp_region" { type = string }

variable "gcp_zone" { type = string }

variable autoscaling_group_max_size { type = number }
variable autoscaling_group_min_size { type = number }

variable "gcp_machine_type" { type = string }

variable "node_pool_image_type" {
  type = string
  default = "COS_CONTAINERD"
}

variable "actian_networks" { type = list }

variable "allowed_networks" { type = list }

variable "cluster_min_master_version" {  type = string}

variable "preemptible_nodes" {
  type = bool
  default = false
}
