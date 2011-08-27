module AnsiArt
  class Converter
    def initialize
      reset_color
    end
    def wait_half_char! # store dual color char left side color
      @leftColor = @color.clone
    end
    def set_color fg,bg,bri
      @color = {:fg => fg, :bg => bg, :bri => bri}
    end
    def set_color_for key,color
      @color[key] = color
    end
    def reset_color
      set_color 7,0,false
    end
    def commit_color
      #this is when new color is ACKed, do nothing by default
    end
    def output
    end
  end
end
