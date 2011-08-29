module AnsiArt
  # Converts ansi art to plain text, removing all colors
  class PlaintextConverter < Converter
    def initialize
      super
      @output = ''
    end

    def put str
      @output += str
    end

    def new_line
      @output += "\n"
    end

    def output
      @output
    end

  end
end
