#encoding: utf-8
class Ansi
  class Converter 
    def initialize
      resetColor
    end
    def waitHalfChar! # store dual color char left side color
      @leftColor = @color.clone
    end
    def setColor fg,bg,bri
      @color = {:fg => fg, :bg => bg, :bri => bri}
    end
    def setColorFor key,color
      @color[key] = color
    end 
    def resetColor
      setColor 7,0,false
    end
    def commitColor
      #this is when new color is ACKed, do nothing by default
    end
    def output
    end
  end

  class PngConverter < Converter
    def initialize width, options
      super()

      # GD Image Library
      if RUBY_VERSION > '1.9'
        require 'gd2-ffij'
      else
        require 'gd2'
        $KCODE = 'u' 
        require 'jcode'
        String.class_eval do
          def ascii_only?
            !self.mb_char?
          end
        end
      end
      self.class.class_eval('include GD2')
      Image.class_eval('def p *arg; end;') # the gd2 gem puts useless data, mute it
     
      @options = options
      @fontsize = width.to_i / 40
      height = @fontsize * 23
      @image = Image::TrueColor.new(width,height)
      @canvas = Canvas.new @image
      @canvas.font = Font::TrueType['./uming.ttc', @fontsize,{
        :dpi => 72,
        :charmap => Font::TrueType::CHARMAP_UNICODE,
        :linespacing => 1.0}]
      @canvas.move 0, - (@drift=@canvas.font.bounding_rectangle('龜')[:upper_left][1])

      @palette = {:normal => [Color[0,0,0],Color[128,0,0],Color[0,128,0],Color[128,128,0],
                              Color[0,0,128],Color[128,0,128],Color[0,128,128],Color[192,192,192]],
                  :bright => [Color[128,128,128],Color[255,0,0],Color[0,255,0],Color[255,255,0],
                              Color[0,0,255],Color[255,0,255],Color[0,255,255],Color[255,255,255]]}
    end
    def put str
      return if str.empty? 

      # if we got a dual color char, draw it now
      unless @leftColor.nil?
        c = str[/./]
        drawChar c,false

        # overlap left part
        @image.with_clipping  x = @canvas.location[0],
                              y = @canvas.location[1] + @drift,
                              x + @fontsize/2 -1,
                              y + @fontsize - 1 do |image|
          drawChar c, true, @leftColor
        end
        str[/./] = ''
        @leftColor = nil
      end

      str.each_char do |c|
        drawChar c
      end
    end
    def newLine
      @canvas.move_to 0, @canvas.location[1] + @fontsize
      # if no enough space for the new line, resize image
      if @canvas.location[1] + @fontsize + @drift > @image.height && !@options[:fixedHeight]
        @image.crop! 0,0,@image.width,@image.height + @fontsize
      end
    end
    def output
      if @options[:path]
        @image.export @options[:path], {:format => 'png',:level => 9}; 
        return @options[:path] # return a path back
      else
        return @image.png(9)
      end
    end
    private
    def drawChar c, move=true, color=@color
      width = @fontsize * ((c.ascii_only?)? 0.5 : 1)

      # draw background first
      @canvas.color = @palette[:normal][color[:bg]]

      x = @canvas.location[0]
      y = @canvas.location[1] + @drift
      @canvas.rectangle x, y, x+width-1, y+@fontsize - 1,true

      # draw text
      @canvas.color = @palette[(color[:bri])? :bright : :normal][color[:fg]]

      @canvas.text c unless graphChar c,x,y

      @canvas.move width,0 if move
    end
    def graphChar ch, x, y
      # right bottom point of full width char
      y2 = y + @fontsize - 1
      x2 = x + @fontsize - 1

      case ch.ord 
      when (0x2581..0x2588)    # 1/8 to full block, see Unicode Spec
        @canvas.rectangle x,             y + (0x2588 - ch.ord).to_f / 8  * @fontsize, 
                          x2, y2, true
      when (0x2589..0x258F) # 7/8 - 1/8 left block
        @canvas.rectangle x, y,
                          x + (0x258F - ch.ord).to_f / 8 * @fontsize, 
                          y2, true 
      when 0x25E2 # /|
        @canvas.polygon [[x,y2], [x2,y], [x2,y2]],true
      when 0x25E3 # |\
        @canvas.polygon [[x,y], [x,y2], [x2,y2]], true
      when 0x25E4 # |/
        @canvas.polygon [[x,y], [x, y2], [x2,y]], true
      when 0x25E5 # \|
        @canvas.polygon [[x,y], [x2,y], [x2,y2]], true
      when 0xFFE3
        @canvas.rectangle x,  y,
                          x2, y + @fontsize / 8, true
      else return false
      end
      true
    end

  end
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
    def commitColor
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

  def initialize ansi
    @ansi = ansi
  end

  def to_html
    return convert HtmlConverter.new
  end

  def to_png w=800, o={}
    return convert PngConverter.new(w,o)
  end

  def convert conv
    buffer = Buffer.new
    ctrl_seq = ""
    high_byte = false  # current status

    @ansi.bytes do |b| 
      if(ctrl_seq.empty? && b != 0x1B) #if is not ctrl sequence
        case b 
          when 10 #newline
            conv.put buffer.to_s!
            conv.newLine
          when 13 #ignore \r 
          else
            buffer.push b
            high_byte = (!high_byte && b > 128)
          end 
        else # is control sequence
          ctrl_seq += (c = [b].pack('C*'))
          if(c.match(/[0-9;\[\x1B]/).nil?) 
            if(c == "m") # terminal color config
              ## ANSI Convert##
              # Remove half byte from string before put to converter
              half_char = buffer.slice!(-1) if high_byte
              # puts string with old color settings
              conv.put buffer.to_s!  unless buffer.empty?
              
              if high_byte
                buffer.push half_char
                # ask converter to store left side color
                conv.waitHalfChar!
              end

              # Strip esc chars and "[" and tail char
              ctrl_seq.gsub! /[\x1B\[]/ , ''
              ctrl_seq.slice! -1

              #split with ";" spliter
              confs = ctrl_seq.split(';')
              if(confs.empty?) #*[m = clear setting
                conv.resetColor
              else
                ctrl_seq.split(';').each do |conf| 
                  case conf = conf.to_i
                    when 0 then conv.resetColor
                    when 1 then conv.setColorFor :bri, true
                    when 30..37 then conv.setColorFor :fg, conf % 10
                    when 40..47 then conv.setColorFor :bg, conf % 10
                  end
                end
              end
              conv.commitColor
            end 
            ctrl_seq = ""
          end
        end
    end
    conv.put buffer.to_s
    return conv.output
  end
  
  private
  class Buffer < Array 
    def initialize
      super
    end
    
    def conv str
      str.encode! 'utf-8','big5-uao',{:invalid => :replace, :undef => :replace}

      # Patch for special chars
      str.tr!("\u00AF","\u203E")

      str
    end

    def to_s
      return conv(self.pack('C*'))
    end

    def to_s! # to string and clean up
      output = self.to_s
      self.clear
      return output
    end
  end
end
