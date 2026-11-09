# frozen_string_literal: true

module Bundler
  module Override
    module DslPatch
      def override(name, **options)
        Bundler::Override.add(name, options[:drop], options[:requirements])
      end
    end
  end
end
