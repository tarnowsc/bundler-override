# frozen_string_literal: true

require_relative "bundler/override/dsl_patch"
require_relative "bundler/override/dependency_patch"
require "bundler/friendly_errors"

module Bundler
  module Override
    class << self
      def override?(name)
        params_map.key?(name)
      end

      def params(name)
        params_map[name] || {}
      end

      def add(name, drop = nil, requirements = nil)
        return if override?(name)

        params_map[name] = { :name => name, :drop => drop || [], :requirements => requirements }
      end

      private

      def params_map
        @params_map ||= {}
      end
    end
  end
end

Bundler::Dsl.prepend(Bundler::Override::DslPatch)
ObjectSpace.each_object(Bundler::Dsl) do |o|
  o.singleton_class.prepend(Bundler::Override::DslPatch)
end
