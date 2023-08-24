# frozen_string_literal: true
require "set"
require_relative "bundler/override/dsl_patch"
require_relative "bundler/override/specset_patch"
require_relative "bundler/override/sharedhelpers_patch"
require "bundler/friendly_errors.rb"

module Bundler
  module Override
    class << self
      def override?(name)
        return unless @gems
        @gems.include? name
      end

      def params(name)
        return [] unless @gems
        return [] unless @gems.include? name
        @params.find { |o| o[:name] == name }
      end

      def add(name, drop, requirements)
        @gems = Set.new unless @gems
        return if @gems.include? name
        @gems << name
        @params = Array.new unless @params
        @params << { :name=>name, :drop=>drop || [], :requirements=>requirements }
      end
    end
  end
end

Bundler::Dsl.prepend(Bundler::Override::DslPatch)
ObjectSpace.each_object(Bundler::Dsl) do |o|
  o.singleton_class.prepend(Bundler::Override::DslPatch)
end

Bundler::SpecSet.prepend(Bundler::Override::SpecSetPatch)

Bundler::SharedHelpers.prepend(Bundler::Override::SharedHelpersPatch)