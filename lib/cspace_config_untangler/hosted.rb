# frozen_string_literal: true

require "fileutils"

module CspaceConfigUntangler
  module Hosted
    module_function

    def tenant_names
      FileUtils.cd(CCU.oo_instance_repo_path) do
        `git pull`
      end
      sites = Dir.new(CCU.oo_site_config_path)
        .children
        .select { |child| child.match?(".tfvars") }
            .map { |child| child.delete_suffix(".tfvars") }
            .reject do |child|
              child.match?(
              /(dev|edu|materialorder|outreachdemo|qa|sandbox|ssotest)$/
            )
            end
          delete_staging_if_prod(sites)
          sites.sort
    end

    def site_url(base) = "https://#{subdomain(base)}.collectionspace.org"

    def config_url(base) = "#{site_url(base)}/cspace/"\
      "#{tenant_base_name(base)}/config"

    def services_url(base) = "#{site_url(base)}/cspace-services/"

    def delete_staging_if_prod(sites)
      sites.select { |site| site.match?(/staging$/) }
        .each { |site| delete_if_prod(sites, site) }
    end
    private_class_method(:delete_staging_if_prod)

    def delete_if_prod(sites, site)
      sites.delete(site) if sites.include?(tenant_base_name(site))
    end
    private_class_method(:delete_if_prod)

    def subdomain(base)
      return "ohiohistory" if base == "ohc"
      return base unless base.end_with?("staging")

      base.sub("staging", ".staging")
    end
    private_class_method(:subdomain)

    def tenant_base_name(base)
      return base unless base.end_with?("staging")

      base.delete_suffix("staging")
    end
    private_class_method(:tenant_base_name)
  end
end
