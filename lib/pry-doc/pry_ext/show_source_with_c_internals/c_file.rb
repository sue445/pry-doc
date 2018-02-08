# Data looks like:
#
# thread.c,11784
# static VALUE rb_cThreadShield;<\x7f>86,2497
# static VALUE sym_immediate;<\x7f>88,2529
# static VALUE sym_on_blocking;<\x7f>89,2557

# First line is the name of the file
# Following lines are the symbols followed by line number with char 127 as separator.
module Pry::CInternals
  class CFile
    SourceLocation = Struct.new(:file, :line, :symbol_type)

    # Used to separate symbol from line number
    SYMBOL_SEPARATOR = "\x7f"

    attr_accessor :symbols, :file_name
    attr_reader :ruby_source_folder

    def initialize(str, ruby_source_folder: nil)
      @ruby_source_folder = ruby_source_folder
      @lines = str.lines
      @file_name = @lines.shift.split(",").first
    end

    def process_symbols
      @symbols = @lines.each_with_object({}) do |v, h|
        symbol, line_number = v.split(SYMBOL_SEPARATOR)
        h[cleanup_symbol(symbol)] = [source_location_for(symbol, line_number)]
      end
    end

    private

    def source_location_for(symbol, line_number)
      SourceLocation.new(full_path_for(@file_name),
                         cleanup_linenumber(line_number), symbol_type_for(symbol.strip))
    end

    def symbol_type_for(symbol)
      if symbol.start_with?("#define")
        :macro
      elsif symbol =~ /\b(struct|enum)\b/
        :struct
      elsif symbol.start_with?("}")
        :typedef_struct
      elsif symbol =~/^typedef.*;$/
        :typedef_oneliner
      elsif symbol =~ /\($/
        :function
      else
        :unknown
      end
    end

    def full_path_for(file)
      File.join(ruby_source_folder, file)
    end

    def cleanup_symbol(symbol)
      symbol = symbol.split.last
      symbol.chomp("(").chomp("*").chomp(";")
    end

    def cleanup_linenumber(line_number)
      line_number.split.first.to_i
    end
  end
end
