#encoding: utf-8
module AnsiArt
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
        draw_char c,false

        # overlap left part
        @image.with_clipping  x = @canvas.location[0],
                              y = @canvas.location[1] + @drift,
                              x + @fontsize/2 -1,
                              y + @fontsize - 1 do |image|
          draw_char c, true, @leftColor
        end
        str[/./] = ''
        @leftColor = nil
      end

      str.each_char do |c|
        draw_char c
      end
    end
    def new_line
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
    def draw_char c, move=true, color=@color
      width = @fontsize * ((c.ascii_only?)? 0.5 : 1)

      # draw background first
      @canvas.color = @palette[:normal][color[:bg]]

      x = @canvas.location[0]
      y = @canvas.location[1] + @drift
      @canvas.rectangle x, y, x+width-1, y+@fontsize - 1,true

      # draw text
      @canvas.color = @palette[(color[:bri])? :bright : :normal][color[:fg]]

      @canvas.text c unless graph_char c,x,y

      @canvas.move width,0 if move
    end
    def graph_char ch, x, y
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
end
