# bundler-override

This [bundler plugin](https://bundler.io/guides/bundler_plugins.html) allows to change dependencies for a gem.
It can be helpful in situation when a developer needs to use some other dependency than default for the gem.

## Requirements

_Ruby_ 3.2 and _Bundler_ 2.4.14 are mostly tested versions.

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
override 'chef-config', :drop => ['chef-utils', 'mixlib-config']
~~~

or

~~~ruby
override 'chef-config', :drop => 'mixlib-config', :requirements => {
  'chef-utils' => '17.10.68'
}
~~~

or

~~~ruby
override 'chef-config', :requirements => {
  'chef-utils' => '17.10.68',
  'mixlib-config' => '2.0.0'
}
~~~

### override

`override` is a command that allows to drop or replace dependency for a gem with desired version

### drop

Takes a gem name or list of gem names to be totally dropped from the dependencies.

### requirements

A map with gem versions to be used instead of the ones from the original dependencies.

## License

The gem is available as open source under the terms of
the [Apache 2.0 License](https://github.com/tarnowsc/bundler-override/blob/main/LICENSE).
