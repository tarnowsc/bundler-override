# bundler-override

This [bundler plugin](https://bundler.io/guides/bundler_plugins.html) allows to change dependencies for a gem.
It can be helpful in situation when a developer needs to use some other dependency than default for the gem.

## Installation

1. Clone this project to your disk

2. Run in the terminal

~~~shell
gem install bundler -v 2.4.14
~~~

3. Install plugin from local git folder

Set proper path in place of 'PATH-TO-THE-FOLDER-WITH-PLUGIN' and run in your project folder:

~~~shell
bundle plugin install "bundler-override" --local-git PATH-TO-THE-FOLDER-WITH-PLUGIN/bundler-override/
~~~



## Usage

1. Add to the Gemfile in your project:

~~~ruby
plugin 'bundler-override'
require File.join(Bundler::Plugin.index.load_paths("bundler-override")[0], "bundler-override") rescue nil
~~~

2. In the Gemfile add 'override' block, e.g.:

~~~ruby
override 'chef-config', :drop => 'chef-utils', :requirements => {
  'chef-utils' => '17.10.68'
}
~~~

or

~~~ruby
override 'chef-config', :drop => ['chef-utils', 'mixlib-config'], :requirements => {
  'chef-utils' => '17.10.68',
  'mixlib-config' => '2.0.0'
}
~~~

## License

The gem is available as open source under the terms of
the [Apache 2.0 License](https://github.com/tarnowsc/bundler-override/blob/main/LICENSE).
