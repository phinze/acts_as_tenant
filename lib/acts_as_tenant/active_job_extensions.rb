module ActsAsTenant
  module ActiveJobExtensions
    extend ActiveSupport::Concern

    module Prepends
      def serialize
        super.tap do |job_data|
          if ActsAsTenant.current_tenant
            job_data["current_tenant"] = ActsAsTenant.current_tenant.to_global_id.to_s
          end
        end
      end

      def deserialize(job_data)
        super
        tenant_global_id = job_data.delete("current_tenant")
        tenant = tenant_global_id ? GlobalID::Locator.locate(tenant_global_id) : nil
        self.job_tenant = tenant
      end
    end

    included do
      prepend Prepends

      attr_accessor :job_tenant

      around_perform do |job, block|
        if job.job_tenant
          ActsAsTenant.with_tenant(job.job_tenant) { block.call }
        else
          block.call
        end
      end
    end
  end
end
