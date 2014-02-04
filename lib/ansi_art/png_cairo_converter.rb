#encoding: utf-8
module AnsiArt
  class PngCairoConverter < Converter
    
    # Public: Initialize a new png targeted converter
    # width - output image width 
    # options - options hash
    #		:path - if specified, store data to path rather than output directly
    #		:reverse_color - reverse all colors to emulate terminal highlight feature 
    def initialize width, options={}
      super()

      # Use Cairo + Pango
      require 'cairo'
      require 'pango'

      @options = options
      @fontsize = width.to_i / 40
      height = @fontsize * 23
      @fontDescription = Pango::FontDescription.new("WenQuanYi Zen Hei Mono #{@fontsize}")
      @surface = Cairo::RecordingSurface.new(0, 0, width, height * 20)
      @width = width
      @realHeight = height
      @context = Cairo::Context.new(@surface)
      @context.fill do 
        @context.set_source_rgb([0, 0, 0])
        @context.rectangle(0, 0, width, height * 10)
      end
      @pangoLayout = @context.create_pango_layout
      @pangoLayout.font_description = @fontDescription
      @pangoLayout.set_text('龜')
      @drift = @pangoLayout.index_to_pos(0).y
      @context.move_to 0, - @drift

      @palette = {:normal => [Cairo::Color.parse([0,0,0]),Cairo::Color.parse([0.5,0,0]),Cairo::Color.parse([0,0.5,0]),Cairo::Color.parse([0.5,0.5,0]),
                              Cairo::Color.parse([0,0,0.5]),Cairo::Color.parse([0.5,0,0.5]),Cairo::Color.parse([0,0.5,0.5]),Cairo::Color.parse([0.75,0.75,0.75])],
                  :bright => [Cairo::Color.parse([0.5,0.5,0.5]),Cairo::Color.parse([1,0,0]),Cairo::Color.parse([0,1,0]),Cairo::Color.parse([1,1,0]),
                              Cairo::Color.parse([0,0,1]),Cairo::Color.parse([1,0,1]),Cairo::Color.parse([0,1,1]),Cairo::Color.parse([1,1,1])]}

      if options[:reverse_color]
        @palette.each do |mode, palette|
          palette.map! do |color|
            Cairo::Color.parse([1-color.red, 1-color.blue, 1 - color.green])
          end
        end
      end
    end
    def put str
      return if str.empty?

      # if we got a dual color char, draw it now
      unless @leftColor.nil?
        c = str[/./]
        draw_char c,false
        # overlap left part
        x = @context.current_point[0]
        y = @context.current_point[1] + @drift
        @context.clip do
          @context.rectangle x, y, @fontsize/2 -1, @fontsize - 1
        end
        @context.move_to(x,y)
        draw_char c, true, @leftColor
        @context.reset_clip
        @context.move_to(x+@fontsize,y)
        str[/./] = ''
        @leftColor = nil
      end

      str.each_char do |c|
        draw_char c
      end
    end
    def new_line
      @context.move_to 0, @context.current_point[1] + @fontsize
      # if no enough space for the new line, resize image
      if @context.current_point[1] + @fontsize + @drift > @realHeight && !@options[:fixedHeight]
        @realHeight += @fontsize
      end
    end
    def output
      if @options[:path]
        @outputSurface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, @width, @realHeight)
        @outputContext = Cairo::Context.new(@outputSurface)
        @outputContext.set_source(@surface)
        @outputContext.paint
        @outputSurface.write_to_png(@options[:path])
      else
        # return @image.png(9)
      end
    end
    private
    def draw_char c, move=true, color=@color
      width = @fontsize * ((c.ascii_only?)? 0.5 : 1)

      x = @context.current_point[0]
      y = @context.current_point[1]
      # draw background first
      @context.fill do
        @context.set_source_color(@palette[:normal][color[:bg]])
        @context.rectangle x, y+@drift, width, @fontsize
      end

      @context.set_source_color(@palette[(color[:bri])? :bright : :normal][color[:fg]])
      unless graph_char c, x, (y+@drift)
        # draw text
        @context.fill do
          @pangoLayout.set_text(c)
          @context.move_to x,y
          @context.show_pango_layout(@pangoLayout)
        end
      end
      if move
        @context.move_to x+width,y
      else
        @context.move_to x,y
      end
    end
    def graph_char ch, x, y
      # right bottom point of full width char
      y2 = y + @fontsize
      x2 = x + @fontsize

      case ch.ord
      when (0x2581..0x2588)    # 1/8 to full block, see Unicode Spec
        @context.rectangle x,             y + (0x2588 - ch.ord).to_f / 8  * @fontsize,
                          x2 - x, y2 - y
      when (0x2589..0x258F) # 7/8 - 1/8 left block
        @context.rectangle x, y,
                          (0x258F - ch.ord).to_f / 8 * @fontsize,
                          y2 - y
      when 0x25E2 # /|
        @context.move_to x, y2
        @context.line_to x2, y
        @context.line_to x2, y2
        @context.close_path
      when 0x25E3 # |\
        @context.move_to x, y
        @context.line_to x, y2
        @context.line_to x2, y2
        @context.close_path
      when 0x25E4 # |/
        @context.move_to x, y
        @context.line_to x, y2
        @context.line_to x2, y
        @context.close_path
      when 0x25E5 # \|
        @context.move_to x, y
        @context.line_to x2, y
        @context.line_to x2, y2
        @context.close_path
      when 0xFFE3
        @context.rectangle x,  y,
                          x2, y + @fontsize / 8
      else return false
      end
      @context.fill
      true
    end
  end
end
