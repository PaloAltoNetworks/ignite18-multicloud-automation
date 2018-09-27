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
 * Terraform output variables for Azure.
 */


data "azurerm_public_ip" "myterraformpublicip" {
  name                = "${azurerm_public_ip.myterraformpublicip.name}"
  resource_group_name = "${azurerm_virtual_machine.panos.resource_group_name}"
}

output "Azure firewall name" {
  value = "${data.azurerm_public_ip.myterraformpublicip.domain_name_label}"
}

output "Azure firewall IP" {
  value = "${data.azurerm_public_ip.myterraformpublicip.ip_address}"
}
