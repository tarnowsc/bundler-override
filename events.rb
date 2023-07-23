Bundler::Plugin.add_hook('before-install-all') do |dependencies|
  warn p(dependencies)
end