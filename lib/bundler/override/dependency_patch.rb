# frozen_string_literal: true

module Bundler
  module Override
    module DependencyPatch
      def self.included(base)
        return if base.method_defined?(:dependencies_orig)

        base.class_eval do
          alias_method :dependencies_orig, :dependencies
          alias_method :runtime_dependencies_orig, :runtime_dependencies if base.method_defined?(:runtime_dependencies)

          def dependencies
            override_dependencies(dependencies_orig) || []
          end

          def runtime_dependencies
            override_dependencies(runtime_dependencies_orig) || []
          end

          def override_dependencies(deps)
            return deps unless deps && Bundler::Override.override?(name)

            param = Bundler::Override.params(name)
            drop = Array(param[:drop])
            requirements = param[:requirements]
            if requirements && !requirements.empty?
              requirements.each do |dep_name, requirement|
                existing = deps.find { |d| d.name == dep_name }
                deps.delete_if { |d| d.name == dep_name }
                deps << Gem::Dependency.new(dep_name, requirement, existing&.type || :runtime)
              end
            end
            deps.delete_if { |d| drop.include? d.name }

            deps
          end
        end
      end
    end
  end
end
