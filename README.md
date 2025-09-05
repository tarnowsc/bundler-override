# bundler-override

This [bundler plugin](https://bundler.io/guides/bundler_plugins.html) allows to change dependencies for a gem.
It can be helpful in situation when a developer needs to use some other dependency than default for the gem.

## Requirements

_Ruby_ >= 3.0 and _Bundler_ >= 2.3.x are required. For detailed compatibility matrix please refer to [test pipeline versions configuration](https://github.com/tarnowsc/bundler-override/blob/main/.github/workflows/ruby.yml#L24).

## Installation

### For normal usage
~~~console
bundle plugin install "bundler-override"
~~~

### For development
1. Clone this project to your disk.

2. Install plugin from local git folder

Set proper path in place of _'PATH-TO-THE-FOLDER-WITH-PLUGIN'_ and run from terminal in your project folder:

~~~console
bundle plugin install "bundler-override" --local-git PATH-TO-THE-FOLDER-WITH-PLUGIN/bundler-override/
~~~

## Usage

1. Add plugin entry to the _Gemfile_ in your project:

~~~ruby
plugin 'bundler-override'
require File.join(Bundler::Plugin.index.load_paths("bundler-override")[0], "bundler-override") rescue nil
~~~

2. Add _'override'_ block to the _Gemfile_, e.g.:

~~~ruby
if Bundler::Plugin.installed?('bundler-override')
  override 'chef-config', :drop => ['chef-utils', 'mixlib-config']
end
~~~

or

~~~ruby
if Bundler::Plugin.installed?('bundler-override')
  override 'chef-config', :drop => 'mixlib-config', :requirements => {
    'chef-utils' => '17.10.68'
  }
end
~~~

or

~~~ruby
if Bundler::Plugin.installed?('bundler-override')
  override 'chef-config', :requirements => {
    'chef-utils' => '17.10.68',
    'mixlib-config' => '2.0.0'
  }
end
~~~



### override

`override` is a command that allows to drop or replace dependency for a gem with desired version

It is a good practice to check if the plugin is installed since it will allow bundler to install it
automatically if it is missing.

### drop

Takes a gem name or list of gem names to be totally dropped from the dependencies.

### requirements

A map with gem versions to be used instead of the ones from the original dependencies.

## License

The gem is available as open source under the terms of
the [Apache 2.0 License](https://github.com/tarnowsc/bundler-override/blob/main/LICENSE).
