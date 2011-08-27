# AnsiArt

This project is under refactoring.

Pending issues:

* Currently it only supports Ruby 1.9.2 or above because it uses `String#encode!`
* It requires `uming.ttc` font file in current working directory. This is inconvenient.
* I left the author information blank in gemspec file. Please fill the information.

I saw there are some code to use `gd2` gem in ruby 1.8.x. I think that doesn't work.

## Requirement

* Ruby 1.9.2 or above
* libgd

## Installation

It's not on rubygems.org yet. Just clone the git reposiory and execute.

    rake install

## Example: Get it working

Put a `uming.tcc` font file in your working directory. 
In Ubuntu it might be at `/usr/share/fonts/truetype/arphic/uming.ttc`.

Download a ansi file:

    wget http://ansi.loli.tw/ansiarts/static/803.ans

And here is the ruby snippet:

    require 'rubygems'
    gem 'ansi_art'
    require 'ansi_art'

    c = AnsiArt::Document.new(IO.read('803.ans'))
    html = c.to_html
    File.open('out.html', 'w') { |f| f.write(html) }
    png = c.to_png
    File.open('out.png', 'wb') { |f| f.write(png) }

You should see `out.html` and `out.png` in your working directory.

