package manageddevopspool

import ujconfig "github.com/crossplane/upjet/v2/pkg/config"

// Configure configures the manageddevopspool group.
func Configure(p *ujconfig.Provider) {
	p.AddResourceConfigurator("azurerm_managed_devops_pool", func(r *ujconfig.Resource) {
		r.ShortGroup = "manageddevopspool"
		r.Kind = "Pool"
	})
}
