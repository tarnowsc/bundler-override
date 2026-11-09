RSpec.describe Bundler::Override do
  let(:bundler_override_root) { Pathname.new(__dir__).join("..").expand_path.to_s }
  let(:base_gemfile) do
    <<~G.chomp
      source "https://rubygems.org"

      plugin "bundler-override", :git => #{bundler_override_root.inspect}, :ref => "HEAD"
      require File.join(Bundler::Plugin.index.load_paths("bundler-override")[0], "bundler-override") rescue nil
    G
  end

  def verify_installation
    expect(out).to include("Fetching #{bundler_override_root}")

    # bundler 2.4.17 removed the "Using" statements in https://github.com/rubygems/rubygems/pull/6804
    if Gem::Version.new(bundler_version) < Gem::Version.new("2.4.17")
      expect(out).to include "Using bundler-override #{Bundler::Override::VERSION}"
    end

    expect(out).to include "Installed plugin bundler-override"
  end


  context "on installation of the plugin - no override block in Gemfile" do
    before do
      write_gemfile "#{base_gemfile}"
    end

    it "installs the plugin using: bundle update" do
      bundle(:update)

      verify_installation
    end

    it "installs the plugin using: bundle update with verbose" do
      bundle(:update, verbose: true)

      verify_installation
    end

    it "installs the plugin using: bundle plugin install" do
      bundle("plugin install \"bundler-override\" --git #{bundler_override_root}")

      verify_installation
    end

    it "installs the plugin using: bundle plugin install verbose" do
      bundle("plugin install \"bundler-override\" --git #{bundler_override_root}", verbose: true)

      verify_installation
    end
  end

  context "on installation of the plugin - override block in Gemfile" do
    before do
      write_gemfile <<~G
        #{base_gemfile}

          gem 'chef-config', '~> 18.2', '>= 18.2.7'
          if Bundler::Plugin.installed?('bundler-override')
            override 'chef-config', :drop => 'chef-utils', :requirements => {
              'chef-utils' => '17.10.95'
            }
          end
      G
    end

    it "installs the plugin using: bundle update" do
      bundle(:update)
      verify_installation
    end

    it "installs the plugin using: bundle plugin install" do
      bundle("plugin install \"bundler-override\" --git #{bundler_override_root}")

      verify_installation
    end
  end

  context "after installation of the plugin" do
    before do
      write_gemfile "#{base_gemfile}"

      bundle(:update)
    end

    it "does not reinstall the plugin" do
      bundle(:update)

      expect(out).to include("Fetching #{bundler_override_root}")

      # bundler 2.4.17 removed the "Using" statements in https://github.com/rubygems/rubygems/pull/6804
      if Gem::Version.new(bundler_version) < Gem::Version.new("2.4.17")
        expect(out).to include "Using bundler-override #{Bundler::Override::VERSION}"
      end

      expect(out).to_not include "Installed plugin bundler-override"
    end
  end

  context "on non existing gems" do
    it "when the gem doesn't exist" do
      write_gemfile <<~G
        #{base_gemfile}
          if Bundler::Plugin.installed?('bundler-override')
            override 'not-existing-gem', :drop => 'chef-utils', :requirements => {
              'chef-utils' => '17.10.68'
            }
          end
      G

      bundle(:update)
    end

    it "when the gem's dependency doesn't exist in rubygems.org" do
      write_gemfile <<~G
        #{base_gemfile}
          gem 'chef-config', '~> 18.2', '>= 18.2.7'

          if Bundler::Plugin.installed?('bundler-override')
            override 'chef-config', :drop => 'chef-utils', :requirements => {
              'not-existing-gem' => '6.6.6'
            }
          end
      G

      bundle(:update, expect_error: true)

      unless bundler_version == '2.3.19' # bundler 2.3.19 does fail with different error message
        expect(err).to include "and not-existing-gem = 6.6.6 could not be found in rubygems repository"
      end
    end
  end

  context "overriding gem" do
    before do
      write_gemfile <<~G
        #{base_gemfile}

          gem 'chef-config', '~> 18.2', '>= 18.2.7'

          if Bundler::Plugin.installed?('bundler-override')
            override 'chef-config', :requirements => {
              'chef-utils' => '17.10.95'
            }
          end
      G
    end

    it "with different version" do
      bundle(:update)

      expect(lockfile_deps_for_spec("chef-config")).to include(["chef-utils", "= 17.10.95"])
    end

    it "with ENV['RAILS_ENV'] = 'production'" do
      bundle(:update, env: { "RAILS_ENV" => "production" })

      expect(lockfile_deps_for_spec("chef-config")).to include(["chef-utils", "= 17.10.95"])
    end
  end

  context "overriding gems" do
    before do
      write_gemfile <<~G
        #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'
        gem 'sequel'

          if Bundler::Plugin.installed?('bundler-override')
            override 'chef-config', :requirements => {
              'chef-utils' => '17.10.95',
              'mixlib-config' => '2.1.0'
            }
          end
      G
    end

    it "with different version" do
      bundle(:update)

      expect(lockfile_deps_for_spec("chef-config")).to include(
                                                         ["chef-utils", "= 17.10.95"],
                                                         ["mixlib-config", "= 2.1.0"])
    end

    it "with ENV['RAILS_ENV'] = 'production'" do
      bundle(:update, env: { "RAILS_ENV" => "production" })

      expect(lockfile_deps_for_spec("chef-config")).to include(
                                                         ["chef-utils", "= 17.10.95"],
                                                         ["mixlib-config", "= 2.1.0"])
    end
  end

  it "overriding with the same version" do
    write_gemfile <<~G
      #{base_gemfile}

        gem 'chef-config', '~> 18.2', '= 18.2.7'

        if Bundler::Plugin.installed?('bundler-override')
          override 'chef-config', :requirements => {
            'chef-utils' => '18.2.7',
            'mixlib-config' => '2.0.0'
          }
        end
    G
    bundle(:update)

    expect(lockfile_deps_for_spec("chef-config")).to include(
                                                       ["chef-utils", "= 18.2.7"],
                                                       ["mixlib-config", "= 2.0.0"])
  end

  it "drop dependency" do
    write_gemfile <<~G
      #{base_gemfile}
        gem 'rails-dom-testing'
        if Bundler::Plugin.installed?('bundler-override')
          override 'rails-dom-testing', drop: ['nokogiri']
        end
    G
    bundle(:update)

    expect(lockfile_deps_for_spec("rails-dom-testing").to_s).to_not include("nokogiri")
  end

  it "drop takes precedence over overwrite" do
      write_gemfile <<~G
        #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'
        gem 'sequel'

          if Bundler::Plugin.installed?('bundler-override')
            override 'chef-config', :drop => ['chef-utils', 'mixlib-config'],:requirements => {
              'chef-utils' => '17.10.95',
              'mixlib-config' => '2.1.0'
            }
          end
      G
      bundle(:update)
      expect(lockfile_deps_for_spec("chef-config").to_s).to_not include('chef-utils')
      expect(lockfile_deps_for_spec("chef-config").to_s).to_not include('mixlib-config')
  end

  it "drops resque's sinatra dependency" do
    write_gemfile <<~G
      #{base_gemfile}
        gem 'resque'
        if Bundler::Plugin.installed?('bundler-override')
          override 'resque', drop: ['sinatra']
        end
    G

    bundle_set(:deployment, true)
    bundle(:install)
    expect(err).to_not include("resque")
    bundle(:lock)
    expect(err).to_not include("resque")
    bundle(:update)
    expect(err).to_not include("resque")
    bundle("exec ruby -e 'puts 1'", verbose: false)
    expect(err).to be_empty

    expect(lockfile_deps_for_spec("resque").to_s).to_not include("sinatra")
  end

  it "loads cleanly when required before default bundler gem is activated" do
    script = <<~RUBY
      Gem.loaded_specs["dummy"] = Gem::Specification.new("dummy", "1.0.0")
      require File.join(RbConfig::CONFIG["rubylibdir"], "bundler.rb")
      require #{File.join(bundler_override_root, "lib/bundler-override").inspect}
    RUBY

    _out, err, status = Spec::Helpers.with_unbundled_env do
      Open3.capture3(RbConfig.ruby, "-e", script)
    end

    expect(status.exitstatus).to eq(0), "Expected clean load, got:\n#{err}"
  end

  describe "unit behavior" do
    after do
      Bundler::Override.instance_variable_set(:@params_map, nil)
    end

    describe ".add, .override?, and .params" do
      it "returns false and empty hash for unknown gems" do
        expect(Bundler::Override.override?("unknown")).to be(false)
        expect(Bundler::Override.params("unknown")).to eq({})
      end

      it "registers a gem with default drop and nil requirements" do
        Bundler::Override.add("foo")

        expect(Bundler::Override.override?("foo")).to be(true)
        expect(Bundler::Override.params("foo")).to eq(:name => "foo", :drop => [], :requirements => nil)
      end

      it "ignores duplicate registrations for the same gem" do
        Bundler::Override.add("foo", ["bar"], { "baz" => "1.0.0" })
        Bundler::Override.add("foo", ["other"], { "baz" => "2.0.0" })

        expect(Bundler::Override.params("foo")).to eq(
          :name => "foo",
          :drop => ["bar"],
          :requirements => { "baz" => "1.0.0" }
        )
      end
    end

    describe Bundler::Override::DslPatch do
      it "registers overrides via Bundler::Dsl#override with and without options" do
        dsl = Bundler::Dsl.new
        dsl.override("gem-a")
        dsl.override("gem-b", :drop => "dep-1", :requirements => { "dep-2" => "~> 1.0" })

        expect(Bundler::Override.params("gem-a")).to eq(:name => "gem-a", :drop => [], :requirements => nil)
        expect(Bundler::Override.params("gem-b")).to eq(
          :name => "gem-b",
          :drop => "dep-1",
          :requirements => { "dep-2" => "~> 1.0" }
        )
      end

      it "patches already-instantiated Bundler::Dsl objects when loaded" do
        dsl = Bundler::Dsl.new
        load File.expand_path("../lib/bundler-override.rb", __dir__)

        expect(dsl.singleton_class.ancestors).to include(Bundler::Override::DslPatch)
      end
    end

    describe Bundler::Override::DependencyPatch do
      let!(:spec) do
        Gem::Specification.new("my-gem", "1.0.0").tap do |s|
          s.add_runtime_dependency("runtime-dep", "~> 1.0")
          s.add_development_dependency("dev-dep", "~> 2.0")
        end
      end

      it "leaves dependencies unchanged when gem is not overridden" do
        expect(spec.dependencies.map(&:name)).to eq(["runtime-dep", "dev-dep"])
        expect(spec.runtime_dependencies.map(&:name)).to eq(["runtime-dep"])
      end

      it "drops specified dependencies from both dependencies and runtime_dependencies" do
        Bundler::Override.add("my-gem", "runtime-dep", nil)

        expect(spec.dependencies.map(&:name)).to eq(["dev-dep"])
        expect(spec.runtime_dependencies).to be_empty
      end

      it "replaces existing requirements while preserving dependency type and adds new runtime dependencies" do
        Bundler::Override.add(
          "my-gem",
          nil,
          { "runtime-dep" => "= 1.5.0", "dev-dep" => "= 2.5.0", "new-dep" => ">= 0.1.0" }
        )

        deps = spec.dependencies
        runtime_dep = deps.find { |d| d.name == "runtime-dep" }
        dev_dep = deps.find { |d| d.name == "dev-dep" }
        new_dep = deps.find { |d| d.name == "new-dep" }

        expect(runtime_dep.requirement.to_s).to eq("= 1.5.0")
        expect(runtime_dep.type).to eq(:runtime)
        expect(dev_dep.requirement.to_s).to eq("= 2.5.0")
        expect(dev_dep.type).to eq(:development)
        expect(new_dep.requirement.to_s).to eq(">= 0.1.0")
        expect(new_dep.type).to eq(:runtime)
      end

      it "gives drop precedence over requirements" do
        Bundler::Override.add("my-gem", ["runtime-dep"], { "runtime-dep" => "= 1.5.0" })

        expect(spec.dependencies.map(&:name)).not_to include("runtime-dep")
      end

      it "returns empty array when original dependencies are nil" do
        allow(spec).to receive(:dependencies_orig).and_return(nil)
        allow(spec).to receive(:runtime_dependencies_orig).and_return(nil)

        expect(spec.dependencies).to eq([])
        expect(spec.runtime_dependencies).to eq([])
      end
    end
  end
end
