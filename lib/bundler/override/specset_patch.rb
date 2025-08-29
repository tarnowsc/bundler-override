require "set"

module Bundler
  module Override
    module SpecSetPatch

      # Old method, pre bundler v
      def specs_for_dependency(dep, platform)
        spec = super
        return spec if spec.empty?
        name = if dep.is_a?(String) then dep else dep.name end
        if Bundler::Override.override? name
          s = spec.first
          param = Bundler::Override.params(name)
          drop = param[:drop]
          s.dependencies.delete_if { |d| drop.include? d.name }
          requirements = param[:requirements]
          if requirements
            gems = Set.new(requirements.keys)
            s.dependencies.delete_if { |d| gems.include? d.name }
            requirements.each { |name, requirement| s.dependencies << Gem::Dependency.new(name, requirement) }
          end
        end
        spec
      end

      # Newer implementation
      def materialize_dependencies(dependencies, platforms = [nil], skips: [])
        handled = ["bundler"].product(platforms).map { |k| [k, true] }.to_h
        deps = dependencies.product(platforms)
        @materializations = []

        loop do
          break unless dep = deps.shift

          dependency = dep[0]
          platform = dep[1]
          name = dependency.name

          key = [name, platform]
          next if handled.key?(key)
          handled[key] = true

          materialization = Materialization.new(dependency, platform, candidates: lookup[name])
          deps.concat(materialization.dependencies) if materialization.complete?

          # --- Our override logic starts here ---
          if Bundler::Override.override?(name)
            # We assume materialization.materialized_spec returns the spec, similar to spec.first before.
            if spec = materialization.materialized_spec
              params = Bundler::Override.params(name)
              if drop = params[:drop]
                spec.dependencies.delete_if { |d| drop.include?(d.name) }
              end
              if requirements = params[:requirements]
                gems = Set.new(requirements.keys)
                spec.dependencies.delete_if { |d| gems.include?(d.name) }
                requirements.each do |dep_name, requirement|
                  spec.dependencies << Gem::Dependency.new(dep_name, requirement)
                end
              end
            end
          end
          # --- End override logic ---

          @materializations << materialization unless skips.include?(name)
        end

        @materializations
      end
    end
  end
end
