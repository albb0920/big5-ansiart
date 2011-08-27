module AnsiArt
  class HtmlConverter < Converter
    def initialize
      super
      @output = '<div><span class="f7 b0">'
    end
    def put str
      putHalfChar str[/./] unless @leftColor.nil?

      # behave like PCMan, need option for user to choose, though
      str.gsub!(/\u00B7/,"\u00B7 ")
      str.gsub!(/\u00A7/,"\u00A7 ")
      str.gsub!(/\uFF89/,"\uFF89 ")
      str.gsub!(/\u2665/,"\u2665 ")

      # HTML special chars
      str.gsub!(/&/, '&amp;')
      str.gsub!(/</, '&lt;')
      str.gsub!(/>/, '&gt;')
      str.gsub!(/"/, '&quot;')

      @output += str.gsub(/ /,'&nbsp;')
    end
    def newLine
      @output += "</span></div><div><span class=\"#{formatColor}\">"
    end
    def commit_color
      @output += '</span><span class="' + formatColor + '">'
    end
    def output
      return @output + '</span></div>'
    end

    private
    def formatColor color=@color
      return "f#{((color[:bri])? 'b' : '')+color[:fg].to_s} b#{color[:bg].to_s}"
    end
    def putHalfChar chr
      @output += "<span class=\"float-char #{formatColor @leftColor}\">#{chr}</span>"
      @leftColor = nil
    end
  end
end
