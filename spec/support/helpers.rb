require "tmpdir"
require "open3"

module Spec
  module Helpers
    def self.bundler_versions
      @bundler_versions ||= begin
        versions = with_unbundled_env do
          `gem list bundler`.lines.grep(/^bundler /).first.scan(/\d+\.\d+\.\d+/)
        end
        versions.reject { |v| v < "2" }
      end
    end

    def self.bundler_version
      return @bundler_version if defined?(@bundler_version)

      versions = bundler_versions

      to_find = ENV["TEST_BUNDLER_VERSION"] || ENV["BUNDLER_VERSION"]
      @bundler_version = versions.detect { |v| v.start_with?(to_find.to_s) }
      raise ArgumentError, "Unable to find bundler version: #{to_find.inspect}" if @bundler_version.nil?

      @bundler_version
    end

    def self.bundler_short_version
      bundler_version.rpartition(".").first
    end

    # Ruby gem binstubs allow you to pass a secret version in order to load a
    # bin file for a particular gem version. This is useful when you have
    # multiple versions of a gem installed and only want to invoke a specific
    # one.
    #
    # So, if I have bundler 1.17.3 and 2.0.1 installed, I can run 1.17.3 with:
    #
    #     bundle _1.17.3_ update
    #
    def self.bundler_cli_version
      "_#{bundler_version}_"
    end

    def self.with_unbundled_env(&block)
      # NOTE: Needed for 2.0 support; when we drop 2.0, this method can go away.
      Bundler.send(Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_clean_env, &block)
    end

    attr_reader :out, :err, :process_status

    def bundler_version
      Helpers.bundler_version
    end

    def bundler_short_version
      Helpers.bundler_short_version
    end

    def app_dir
      @app_dir ||= Pathname.new(Dir.mktmpdir)
    end

    def rm_app_dir
      return unless @app_dir
      FileUtils.rm_rf(@app_dir)
      @app_dir = nil
    end

    def with_path_based_gem(source_repo)
      Dir.mktmpdir do |path|
        path = Pathname.new(path)
        Dir.chdir(path) do
          out, status = Open3.capture2e("git clone --depth 1 #{source_repo} the_gem")
          raise "An error occured while cloning #{source_repo.inspect}...\n#{out}" unless status.exitstatus == 0
        end
        path = path.join("the_gem")

        yield path
      end
    end

    def write_gemfile(contents)
      contents = "#{coverage_prelude}\n\n#{contents}"
      File.write(app_dir.join("Gemfile"), contents)
      lockfile_path = app_dir.join("Gemfile.lock")
      File.delete(lockfile_path) if File.exist?(lockfile_path)
    end

    def lockfile
      file = app_dir.join("Gemfile.lock")
      Bundler::LockfileParser.new(file.read) if file.exist?
    end

    def lockfile_specs
      return unless (lf = lockfile)
      lf.specs.map { |s| [s.name, s.version.to_s] }
    end

    def lockfile_deps_for_spec(spec_name)
      return unless (lf = lockfile)
      spec = lf.specs.detect { |s| s.name == spec_name}
      spec.dependencies.map { |d| [d.name, d.requirement.to_s] }
    end

    def raw_bundle(command, verbose: false, env: {})
      command = "bundle #{Helpers.bundler_cli_version} #{command} #{"--verbose" if verbose}".strip
      out, err, process_status = Helpers.with_unbundled_env do
        Open3.capture3(env, command, :chdir => app_dir)
      end
      return command, out, err, process_status
    end

    def bundle_set(param, value, verbose: true)
      raw_bundle("set #{param} #{value}", verbose: verbose)
    end

    def bundle(command, expect_error: false, verbose: true, env: {})
      command, @out, @err, @process_status = raw_bundle(command, verbose: verbose, env: env)
      if verbose
        puts "\n#{'=' * 80}\n#{command}\n#{'=' * 80}\n#{bundler_output}\n#{'=' * 80}\n"
        puts "Gemfile.lock:\n#{File.read(app_dir.join("Gemfile.lock"))}" if File.exist?(app_dir.join("Gemfile.lock"))
        puts "App dir: #{app_dir}"
      end
      if expect_error
        expect(@process_status.exitstatus).to_not eq(0), "#{command.inspect} succeeded but was not expected to:\n#{bundler_output}"
      else
        expect(@process_status.exitstatus).to eq(0), "#{command.inspect} failed with:\n#{bundler_output}"
      end
    end

    def bundler_output
      s = StringIO.new
      s.puts "== STDOUT ===============".light_magenta
      s.puts out unless out.empty?
      s.puts "== STDERR ===============".light_magenta
      s.puts err unless err.empty?
      s.puts "== STATUS ===============".light_magenta
      s.puts process_status
      s.puts "=========================".light_magenta
      s.string
    end

  end
end
