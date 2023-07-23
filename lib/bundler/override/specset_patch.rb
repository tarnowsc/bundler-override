module Bundler
  module Override
    module SpecSetPatch

      def specs_for_dependency(dep, platform)
        spec = super
        return spec if spec.empty?
        if Bundler::Override.override? dep.name
          s = spec.first
          param = Bundler::Override.params(dep.name)
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

    end
  end
end
