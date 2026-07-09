package azurerm

import (
	ujconfig "github.com/crossplane/upjet/v2/pkg/config"
)

// Configure configures the Azure DevOps group
func Configure(p *ujconfig.Provider) {
	p.AddResourceConfigurator("azurerm_managed_devops_pool", func(r *ujconfig.Resource) {
		r.Kind = "ManagedDevOpsPool"
		r.ShortGroup = "devopsinfra"
	})
}
