/*
 * Copyright 2018 Palo Alto Networks
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/*
 * Terraform variable declarations for Azure.
 */

variable "azure_resource_group" {
    description = "Azure Resource Group"
    type = "string"
}

variable "azure_location" {
    description = "Ireland"
    type = "string"
    default = "northeurope"
}

variable "azure_environment" {
    default = "Ignite 18 Automation Workshop"
}

variable "azure_ssh_key" {
    description = "Full path to the SSH public key file"
    type = "string"
    default = "~/.ssh/lab_ssh_key.pub"
}

variable "azure_firewall_user" {
    description = "Firewall administrator username"
    type = "string"
    default = "admin"
}

variable "azure_firewall_password" {
    description = "Firewall administrator password"
    type = "string"
}
