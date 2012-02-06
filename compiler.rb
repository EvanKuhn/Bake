#===============================================================================
# Compiler class for the Bake utility. This is responsible for compiling code.
# If we need to support multiple compilers, we can write a separate class for
# each compiler.
#
# Evan Kuhn, 2012-02-02
#===============================================================================
require 'constants'
require 'project'
require 'utils'

module Bake
  
  class Compiler
    attr_accessor :verbose
    
    # Build (compile) a project
    def build(project)
      puts "Compiling project '#{project.name}':"
      puts

      # Temp data
      obj_files = []
      num_errors = 0
      error_str = ''
      
      # Make sure the temp output dir exists
      Dir.mkdir(BAKE_DIR) if(!Dir.exists? BAKE_DIR)
      compiler_output_file = BAKE_DIR  + COMPILER_OUTPUT_FILENAME
      
      # Compile each file
      project.files.each do |src_file|
        # Get the object filename 
        obj_file = BAKE_DIR + src_file.sub(/\.[\w+]+$/, ".o")
        obj_files << obj_file
        
        # Run the command and save output in a temp file
        print "  #{src_file}"
        command = "g++ -c #{src_file} -o #{obj_file}"
        system(command + ' &> ' + compiler_output_file)

        # If the command failed, record the errors
        if !$?.success?
          print " (failed)"
          num_errors += 1
          error_str += Utils.read_file(compiler_output_file, '  ')
        end
        print "\n"
      end
      
      # If there were compiler errors, print them and quit
      if num_errors > 0
        print "\nCompiler errors:\n\n#{error_str}\n"
        return
      end
      
      # There were no errors, so link
      if num_errors == 0
        print "  (linking)\n\n"

        case project.type
        when ProjectType::APP
          # Run the linker command
          command = "g++ -o #{project.name} " + obj_files.join(' ')
          system(command + ' &> ' + compiler_output_file)

          # If the command failed, record the errors
          if !$?.success?
            num_errors += 1
            error_str = Utils.read_file(compiler_output_file, '  ')
          end
        when ProjectType::LIB
          #TODO
          puts "*** I don't know how to create static libraries yet! ***"
          return
        when ProjectType::DLL
          #TODO
          puts "*** I don't know how to create dynamic libraries yet! ***"
          return
        end
      end
      
      # Print success or failure
      if num_errors == 0
        puts 'Success!'
      else
        print "Linker errors:\n\n#{error_str}\n"
      end
    end
  end

end # module Bake
