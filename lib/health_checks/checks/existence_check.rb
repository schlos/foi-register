module HealthChecks
    module Checks
        class ExistenceCheck
            include HealthChecks::HealthCheckable

            attr_reader :should_exist, :subject

            def initialize(args = {}, &block)
                @should_exist = args.fetch(:should_exist) { true }
                @subject = block
                super(args)
            end

            def failure_message
                "#{ super }: #{ subject.call }"
            end

            def success_message
                "#{ super }: #{ subject.call }"
            end

            def check
                if should_exist
                    subject.call.present?
                else
                    subject.call.nil?
                end
            end

        end
    end
end