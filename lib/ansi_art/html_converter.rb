module AnsiArt
  class HtmlConverter < Converter
    def initialize
      super
      @output = '<div><span class="f7 b0">'
    end
    def put str
      put_half_char str[/./] unless @leftColor.nil?

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
    def new_line
      @output += "</span></div><div><span class=\"#{format_color}\">"
    end
    def commit_color
      @output += '</span><span class="' + format_color + '">'
    end
    def output
      return @output + '</span></div>'
    end

    private
    def format_color color=@color
      return "f#{((color[:bri])? 'b' : '')+color[:fg].to_s} b#{color[:bg].to_s}"
    end
    def put_half_char chr
      @output += "<span class=\"float-char #{format_color @leftColor}\">#{chr}</span>"
      @leftColor = nil
    end
  end
end
