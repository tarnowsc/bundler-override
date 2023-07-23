module Bundler
  module Override
    module SharedHelpersPatch

      def ensure_same_dependencies(spec, old_deps, new_deps)
        if Bundler::Override.override? spec.name
          new_deps.clear()
          new_deps.push(*old_deps)
        end
        super
      end
    end
  end
end