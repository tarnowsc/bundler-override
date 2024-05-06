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
      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")

      verify_installation
    end

    it "installs the plugin using: bundle plugin install verbose" do
      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}", verbose: true)

      verify_installation
    end
  end

  context "on installation of the plugin - override block in Gemfile" do
    before do
      write_gemfile <<~G
      #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'

        override 'chef-config', :drop => 'chef-utils', :requirements => {
          'chef-utils' => '17.10.68'
        }
      G
    end

    it "installs the plugin using: bundle update" do
      bundle(:update, expect_error: true)

      expect(err).to include "There was an error parsing `Gemfile`: Undefined local variable or method `override'"
      expect(err).to include "'chef-utils' => '17.10.68'"
    end

    it "installs the plugin using: bundle plugin install" do
      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")

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

        override 'not-existing-gem', :drop => 'chef-utils', :requirements => {
          'chef-utils' => '17.10.68'
        }
      G

      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")
      bundle(:update)
    end

    it "when the gem's dependency doesn't exist in rubygems.org" do
      write_gemfile <<~G
      #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'

        override 'chef-config', :drop => 'chef-utils', :requirements => {
          'not-existing-gem' => '6.6.6'
        }
      G

      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")
      bundle(:update, expect_error: true)

      expect(err).to include "and not-existing-gem = 6.6.6 could not be found in rubygems repository"
    end
  end

  context "overriding gem" do
    before do
      write_gemfile <<~G
      #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'

        override 'chef-config', :drop => 'chef-utils', :requirements => {
          'chef-utils' => '17.10.68'
        }
      G

      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")
    end

    it "with different version" do
      bundle(:update)

      expect(lockfile_deps_for_spec("chef-config")).to include(["chef-utils", "= 17.10.68"])
    end

    it "with ENV['RAILS_ENV'] = 'production'" do
      bundle(:update,env: { "RAILS_ENV" => "production" })

      expect(lockfile_deps_for_spec("chef-config")).to include(["chef-utils", "= 17.10.68"])
    end

    it "with ENV['RAILS_ENV'] = 'production' and the Bundler::Setting false" do
      env_var = "BUNDLE_BUNDLER_INJECT__DISABLE_WARN_OVERRIDE_GEM"
      bundle(:update, env: { "RAILS_ENV" => "production", env_var => 'false' })

      expect(lockfile_deps_for_spec("chef-config")).to include(["chef-utils", "= 17.10.68"])
    end
  end

  context "overriding gems" do
    before do
      write_gemfile <<~G
      #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'

        override 'chef-config', :drop => ['chef-utils', 'mixlib-config'], :requirements => {
          'chef-utils' => '17.10.68',
          'mixlib-config' => '2.0.0'
        }
      G

      bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")
    end

    it "with different version" do
      bundle(:update)

      expect(lockfile_deps_for_spec("chef-config")).to include(
                                                         ["chef-utils", "= 17.10.68"],
                                                         ["mixlib-config", "= 2.0.0"])
    end

    it "with ENV['RAILS_ENV'] = 'production'" do
      bundle(:update,env: { "RAILS_ENV" => "production" })

      expect(lockfile_deps_for_spec("chef-config")).to include(
                                                         ["chef-utils", "= 17.10.68"],
                                                         ["mixlib-config", "= 2.0.0"])
    end

    it "with ENV['RAILS_ENV'] = 'production' and the Bundler::Setting false" do
      env_var = "BUNDLE_BUNDLER_INJECT__DISABLE_WARN_OVERRIDE_GEM"
      bundle(:update, env: { "RAILS_ENV" => "production", env_var => 'false' })

      expect(lockfile_deps_for_spec("chef-config")).to include(
                                                         ["chef-utils", "= 17.10.68"],
                                                         ["mixlib-config", "= 2.0.0"])
    end
  end

  it "overriding with the same version" do
    write_gemfile <<~G
      #{base_gemfile}

        gem 'chef-config', '~> 18.2', '>= 18.2.7'

        override 'chef-config', :drop => 'chef-utils', :requirements => {
          'chef-utils' => '18.2.7',
          'mixlib-config' => '2.0.0'
        }
      G

    bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")
    bundle(:update)

    expect(lockfile_deps_for_spec("chef-config")).to include(
                                                       ["chef-utils", "= 18.2.7"],
                                                       ["mixlib-config", "= 2.0.0"])
  end

  it "drop dependency" do
    write_gemfile <<~G
      #{base_gemfile}
        gem 'rails-dom-testing'
        override 'rails-dom-testing', drop: ['nokogiri']
      G

    bundle("plugin install \"bundler-override\" --local-git #{bundler_override_root}")
    bundle(:update)

    puts lockfile_deps_for_spec("rails-dom-testing")
    expect(lockfile_deps_for_spec("rails-dom-testing")).to_not include(
                                                       ["nogokiri"])
  end
end
