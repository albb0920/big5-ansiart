module AnsiArt
  class Document
    def initialize ansi
      @ansi = ansi
    end

    def to_html
      return convert HtmlConverter.new
    end

    def to_png w=800, o={}
      return convert PngConverter.new(w,o)
    end

    def to_plaintext
      return convert PlaintextConverter.new
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
              conv.new_line
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
                  conv.wait_half_char!
                end

                # Strip esc chars and "[" and tail char
                ctrl_seq.gsub! /[\x1B\[]/ , ''
                ctrl_seq.slice! -1

                #split with ";" spliter
                confs = ctrl_seq.split(';')
                if(confs.empty?) #*[m = clear setting
                  conv.reset_color
                else
                  ctrl_seq.split(';').each do |conf|
                    case conf = conf.to_i
                      when 0 then conv.reset_color
                      when 1 then conv.set_color_for :bri, true
                      when 30..37 then conv.set_color_for :fg, conf % 10
                      when 40..47 then conv.set_color_for :bg, conf % 10
                    end
                  end
                end
                conv.commit_color
              end
              ctrl_seq = ""
            end
          end
      end
      conv.put buffer.to_s
      return conv.output
    end
  end
end
