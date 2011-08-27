module AnsiArt
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
