module Bundler
  module Override
    module DependencyPatch
      def self.included(base)
        base.class_eval do
          alias_method :dependencies_orig, :dependencies

          def dependencies
            override_dependencies || []
          end

          def override_dependencies
            deps = dependencies_orig
            return deps unless Bundler::Override.override? name
            param = Bundler::Override.params(name)
            drop = Array(param[:drop])
            requirements = param[:requirements]
            if requirements && !requirements.empty?
              requirements.each do |name, requirement|
                existing = deps.find { |d| d.name == name }
                deps.delete_if { |d| d.name == name }
                deps << Gem::Dependency.new(name, requirement, existing&.type || :runtime)
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

module Bundler
  class RemoteSpecification
    include Override::DependencyPatch
  end

  class EndpointSpecification
    include Override::DependencyPatch
  end
end

module Gem
  class Specification
    include Bundler::Override::DependencyPatch
  end
end