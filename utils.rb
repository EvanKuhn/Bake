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
  end

end # module Bake
