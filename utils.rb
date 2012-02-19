#===============================================================================
# Utilities for bake
#
# Evan Kuhn, 2012-01-31
#===============================================================================

module Bake

  class Utils
    # Return the contents of a file
    def self.read_file(filename, indent='')
      File.open(filename) do |file|
        contents = ''
        while(line = file.gets)
          contents += indent + line
        end
        return contents
      end
    end

    # Write to a file. Will overwrite.
    def self.write_file(filename, contents)
      File.open(filename, 'w') do |f|
        f.write contents
      end
    end
    
    # Private implementation of get_source_files()
    def self.get_source_files_impl(dir, recurse, output)
      # Convert the directory to an absolute path
      #dir = File.absolute_path(dir)

      Dir.entries(dir).each do |filename|
        # Skip the current and parent dirs
        next if(filename == '.' || filename == '..')
        
        # If recursion is enabled and the file is a directory, search it.
        # Otherwise, check if the file is a source file based on its extension.
        # If so, add it to the output array.
        if(recurse && File.directory?(filename))
          get_source_files_impl(File.path(filename), recurse, output)
        elsif(File.extname(filename) =~ /^\.(c|cc|cpp|cxx|c++)$/)
          # Construct the relative file path without the preceding "./"
          file_path = dir + '/' + filename
          file_path.sub!(/^\.\//, '')
          output << file_path
        end
      end
    end
    
    # Given a directory, return all source files in that directory
    # - May optionally recurse into subdirectories
    # - Returns a sorted list full file paths
    def self.get_source_files_in_dir(dir, recurse)
      output = []
      if(Dir.exists?(dir))
        get_source_files_impl(dir, recurse, output)
        output.sort!
      end
      return output
    end

    # Find all C++ source files in the current directory
    # - Does not recursively search subdirectories
    def self.get_source_files()
      return get_source_files_in_dir('.', false)
    end

    # Parse a block of lines and return the 'contents', which are the lines
    # within the block. For example, will parse:
    #
    #    projects {
    #      foo
    #      bar
    #    }
    #
    def self.parse_unnamed_block(lines, contents)
      # Tokenize the first line
      raise 'No lines to parse' if lines.empty?
      curline = lines.shift
      tokens = curline.split

      # Check for errors and read til the opening brace
      if tokens.size < 1
        raise "Unnamed block declaration expects one token '<type>'"
      elsif tokens[0] !~ /^[\w-]+$/
        raise "Invalid block type string '#{tokens[0]}'"
      elsif tokens.size == 1 && lines.shift != "{"
        raise "Expected '{' after unnamed block declaration"
      elsif tokens.size == 2 && tokens[1] == '{}'
        return
      elsif tokens.size > 1 && tokens[1] != '{'
        raise "Expected '{' after unnamed block declaration"
      elsif tokens.size > 2 && tokens[2] != "}"
        raise "Expected '}' as third token of unnamed block declaration '#{curline}'"
      elsif tokens.size > 3
        raise "Invalid block declaration '#{curline}'"
      end

      # Read contents
      while true
        curline = lines.shift
        raise "Unexpected end of block definition" if curline.nil?
        return if curline == '}'
        contents << curline
      end
    end

    # Parse a named block of lines and return both the name and contents. For
    # example, will parse:
    #
    #    build dogs {
    #      german_shepherd
    #      bulldog
    #    }
    #
    def self.parse_named_block(lines, name, contents)
      # Tokenize the first line
      raise 'No lines to parse' if lines.empty?
      curline = lines.shift
      tokens = curline.split

      # Check for errors and read til the opening brace
      if tokens.size < 2
        raise "Named block declaration expects two tokens '<type> <name>'"
      elsif tokens[0] !~ /^[\w-]+$/
        raise "Invalid block type string '#{tokens[0]}'"
      elsif tokens[1] !~ /^[\w-]+$/
        raise "Invalid block name string '#{tokens[1]}'"
      elsif tokens.size == 3 && tokens[2] == '{}'
        name.clear
        name << tokens[1]
        return
      elsif tokens.size > 2 && tokens[2] != '{'
        raise "Expected '{' after named block declaration"
      elsif tokens.size > 3 && tokens[3] != "}"
        raise "Expected '}' as 4th token of named block declaration '#{curline}'"
      elsif tokens.size > 4
        raise "Invalid block declaration '#{curline}'"
      end

      # Save name
      name.clear
      name << tokens[1]
      
      # Read contents
      while true
        curline = lines.shift
        raise "Unexpected end of block definition" if curline.nil?
        return if curline == '}'
        contents << curline
      end
    end
  end

end # module Bake
