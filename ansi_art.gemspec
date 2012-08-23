# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ansi_art/version"

Gem::Specification.new do |s|
  s.name        = "ansi_art"
  s.version     = AnsiArt::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["albb0920", "miaout17"]
  s.email       = ["albb0920@gmail.com"]
  s.homepage    = "https://github.com/albb0920/big5-ansiart"
  s.summary     = %q{ANSI AsciiArt Renderer}
  s.description = %q{Render AsciiArt to HTML and PNG format}

  s.rubyforge_project = "ansi_art"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'cairo', '~> 1.10.0'
  s.add_dependency 'pango', '~> 1.1.4'
  s.add_dependency 'gd2-ffij', '~> 0.0.3'
  s.add_dependency 'ffi', '~> 1.0.9'
end
