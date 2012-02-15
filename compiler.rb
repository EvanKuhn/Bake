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
      begin
        puts "Compiling project '#{project.name}':"
        puts

        # Make sure the temp output dir exists
        Dir.mkdir(BAKE_DIR) if(!Dir.exists? BAKE_DIR)
        
        # Compile each file
        compile_source_files(project)
        
        # Then link
        print "  (linking)\n\n"
        
        case project.type
        when ProjectType::APP
          link_app(project)
        when ProjectType::LIB
          link_lib(project)
        when ProjectType::DLL
          link_dll(project)
        end

        # Done
        puts 'Success!'
      rescue => e
        print e.message
      end
    end
  
    # Compile all source files within a project
    # - Will populate the instance variables @obj_files
    def compile_source_files(project)
      @obj_files = []
      num_errors = 0
      error_str = ''

      # Compile files
      project.files.each do |src_file|
        print "  #{src_file}"

        # Get the object filename 
        obj_file = BAKE_DIR + src_file.sub(/\.[\w+]+$/, ".o")
        @obj_files << obj_file

        # Build the compile command
        command = "g++ -c #{src_file} -o #{obj_file}"
        if !project.inc_paths.empty?
          command += ' -I' + project.inc_paths.join(' -I')
        end

        # Run the command and save output in a temp file
        system(command + ' &> ' + COMPILER_OUTPUT_FILE)
        
        # If the command failed, record the errors
        if !$?.success?
          print " (failed)"
          num_errors += 1
          error_str += Utils.read_file(COMPILER_OUTPUT_FILE, '  ')
        end
        print "\n"
      end

      # Raise errors if we encountered any
      raise "\nCompiler errors:\n\n#{error_str}\n" if num_errors > 0
    end

    # Link object files into an application
    def link_app(project)
      begin
        # Check for object files
        raise "  No object files found" if @obj_files.empty?

        # Build the linker command
        command = "g++ -o #{project.name} " + @obj_files.join(' ')
        if !project.lib_paths.empty?
          command += ' -L' + project.lib_paths.join(' -L')
        end
        if !project.libs.empty?
          command += ' -l' + project.libs.join(' -l')
        end
        
        # Run the linker command
        system(command + ' &> ' + COMPILER_OUTPUT_FILE)
        
        # If the command failed, raise the errors
        raise Utils.read_file(COMPILER_OUTPUT_FILE, '  ') if !$?.success?
      rescue => e
        raise raise "Linker Errors:\n\n#{e.message}\n"
      end
    end

    # Link object files into a static library
    def link_lib(project)
      begin
        # Check for object files
        raise "  No object files found" if @obj_files.empty?
        
        # Run the linker command
        command = "ar -cvq lib#{project.name}.a " + @obj_files.join(' ')
        system(command + ' &> ' + COMPILER_OUTPUT_FILE)
        
        # If the command failed, raise the errors
        raise Utils.read_file(COMPILER_OUTPUT_FILE, '  ') if !$?.success?
      rescue => e
        raise raise "Linker Errors:\n\n#{e.message}\n"
      end
    end

    # Link object files into a shared library
    def link_dll(project)
      begin
        # Check for object files
        raise "  No object files found" if @obj_files.empty?
        
        # Run the linker command
        command = "g++ -shared -o lib#{project.name}.so " + @obj_files.join(' ')
        system(command + ' &> ' + COMPILER_OUTPUT_FILE)
        
        # If the command failed, raise the errors
        raise Utils.read_file(COMPILER_OUTPUT_FILE, '  ') if !$?.success?
      rescue => e
        raise raise "Linker Errors:\n\n#{e.message}\n"
      end
    end
    
    # Output file used for temporary compiler/linker output
    COMPILER_OUTPUT_FILE = BAKE_DIR + COMPILER_OUTPUT_FILENAME
    
  end # class Compiler

end # module Bake
