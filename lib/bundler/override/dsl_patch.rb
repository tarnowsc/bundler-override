module Bundler
  module Override
    module DslPatch
      def override(name, *args)
        Bundler::Override.add(name, args.last[:drop], args.last[:requirements])
      end
    end
  end
end
