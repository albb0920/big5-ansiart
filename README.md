# AnsiArt

This project is under refactoring.

Pending issues:

* Currently it only supports Ruby 1.9.2 or above because it uses `String#encode!`
* It requires `uming.ttc` font file in current working directory. This is inconvenient.
* The CSS should be moved somewhere else.

I saw there are some code to use `gd2` gem in ruby 1.8.x. I think that doesn't work.

## Requirement

* Ruby 1.9.2 or above
* libgd

## Installation

It's not on rubygems.org yet. Just clone the git reposiory and execute.

    rake install

## Example: Get it working

This gem requires CJK font `AR PL UMing` for PNG rendering, which is licensed under Arphic Public License.
Put a `uming.tcc` font file in your working directory. 

Ways to find it:

* In Ubuntu, it might be at `/usr/share/fonts/truetype/arphic/uming.ttc`.
* Download it from [freedesktop.org] (http://www.freedesktop.org/wiki/Software/CJKUnifonts/Download)

Download a ansi file:

    wget http://ansi.loli.tw/ansiarts/static/803.ans

And here is the ruby snippet:

    require 'rubygems'
    gem 'ansi_art'
    require 'ansi_art'

    doc = AnsiArt::Document.new(IO.read('803.ans'))
    File.open('out.html', 'w') { |f| f.write(doc.to_html) }
    File.open('out.png', 'wb') { |f| f.write(doc.to_png) }

You should see `out.html` and `out.png` in your working directory.

## Make HTML display correctly
HTML output needs to be wraped under a `<div class="ansi-block">` tag, and apply required css files.

Example:

    <!doctype html>
    <html>
	<head>
	    <title>ANSI art test page</title>
	    <link href="ansi.css" rel="stylesheet" type="text/css">
	    <!--[if IE 9]>
	    <link href="ansi.ie9.css" rel="stylesheet" type="text/css">
	    <![endif]-->
	</head>
	<body>
	    <div class="ansi-block">
		<%= c.to_html %>
	    </div>
	</body>
    </html>

