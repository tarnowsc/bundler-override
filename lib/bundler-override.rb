# frozen_string_literal: true

require_relative "bundler/override"
require_relative "bundler/override/dependency_patch"
require_relative "bundler/override/dsl_patch"

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

Bundler::Dsl.prepend(Bundler::Override::DslPatch)
ObjectSpace.each_object(Bundler::Dsl) do |o|
  o.singleton_class.prepend(Bundler::Override::DslPatch)
end
