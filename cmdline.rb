#===============================================================================
# Command-line input parser.
#
# Handles short and long options. Eg:
#
#     my_program -h
#     my_program --help
#
# Handles options with or without values. Eg:
# 
#     my_program -a            (no value)
#     my_program -b 1          (with value)
#     my_program --version     (no value)
#     my_program --number 4    (with value)
#     my_program --number=4    (with value)
#
# Separates options and params. Eg:
#
#     my_program -a foo --bar 123
#     options: -a, --bar    (assuming neither accept values)
#     params: foo, 123
#
# Evan Kuhn, 2012-02-15
#===============================================================================

#===============================================================================
# Each option has:
#
# - A short name (-v)
# - A long name  (--version)
# - Option-given flag
# - Has-associated-value flag
# - Actual value provided
#===============================================================================
class OptionData
  attr_accessor :short_name, :long_name, :given, :has_value, :value
  alias_method :given?, :given
  alias_method :has_value?, :has_value

  # Initialize takes:
  # - A spec string. Eg: "h", "help", or "h,help"
  # - Value expected?
  def initialize(spec, has_value)
    # Parse spec string
    if(spec =~ /^[a-zA-Z0-9]$/)
      @short_name = spec
    elsif(spec =~ /^[a-zA-Z][\w\-]+$/)
      @long_name = spec
    elsif(spec =~ /^([a-zA-Z0-9]),([a-zA-Z][\w\-]+)$/)
      @short_name = $1
      @long_name = $2
    else
      raise "Invalid option spec '#{spec}'"
    end

    # Finish initialization
    @has_value = has_value
  end
end

#===============================================================================
# Command-line input parser
#===============================================================================
class CommandLine
  def initialize
    @options = {}  # Map from option name to data
    @params = []   # Non-option args
  end
  
  # Add an option to parse.
  #
  # Params:
  #   1) The option character and/or name. Eg: "h,help", "h", or "help",
  #      depending on which ones you want to accept.
  #   2) Whether or not the option expects an associated value.
  #
  # Notes:
  #   - Options must start with an alphanumeric character.
  #   - Subsequent characters can include '-' or '_'.
  #   - Will raise an exception if the option was already added.
  def option(spec, has_value=false)
    # Parse the spec and check if the option has already been specified
    data = OptionData.new(spec, has_value)
    raise "Option '#{key}' already specified" if accepts? data.short_name
    raise "Option '#{key}' already specified" if accepts? data.long_name

    # Store the option's index and data
    @options[data.short_name] = data if !data.short_name.nil?
    @options[data.long_name]  = data if !data.long_name.nil?
  end

  # Parse the command line args
  def parse(args)
    arg_index = 0
    while arg_index < args.size
      arg = args[arg_index]

      if arg.start_with? '--'
        # Argument is a long option (eg: --verbose)
        op = arg[2,arg.length]
        value = nil

        # Check if the option and value are specified together ("--op=value")
        eql_index = op.index '='
        if !eql_index.nil?
          # Split "op=value" string and store
          value = op[eql_index+1, op.size]
          op = op[0, eql_index]
        end

        # Check if option is accepted
        raise "Option '--#{op}' not accepted" if !accepts? op

        # Remember that the option was specified
        data = @options[op]
        data.given = true

        # Check if given a value that wasn't expected
        if !data.has_value? && !eql_index.nil?
          raise "Option '--#{op}' does not expect a value"
        end
        
        # Get associated value
        if data.has_value?
          # If the option was not given as "op=value", get the next value.
          # Otherwise, save the value we stored before
          if eql_index.nil?
            # Get index of next value
            arg_index += 1
            # Make sure we actually have a value to save
            if arg_index >= args.size
              raise "Option '--#{op}' must be followed by a value"
            end
            # Then save the value
            data.value = args[arg_index]
          else
            data.value = value
          end
        end

      elsif arg.start_with? '-'
        # Argument is a short option (eg: -a, -abc)
        op = arg[1,arg.length]
        
        # Make sure each character is accepted
        op.chars.each_with_index do |c,i|
          # Check for errors
          raise "Option '-#{c}' not accepted" if !accepts? c

          # Remember that the option was specified
          data = @options[c]
          data.given = true

          # Check for and save the option's values
          if data.has_value?
            # Get index of next value
            arg_index += 1
            # Make sure we actually have a value to save
            if arg_index >= args.size || i >= op.size
              raise "Option '-#{c}' must be followed by a value"
            end
            # Then save the value
            data.value = args[arg_index]
          end
        end

      else
        # Argument is a param (ie. not an option)
        @params << arg
      end

      # Increment argument index
      arg_index += 1
    end
  end
  
  # Will this object accept the given option string?
  def accepts?(op)
    return @options.has_key? op
  end

  # Check if the option has been specified at the command line
  def has?(op)
    return false if !accepts? op
    return @options[op].given?
  end

  # Get the value for the given option
  # - Raises an error if the option hasn't been specified
  # - Returns nil if no values are expected 
  # - Returns the value if only one is expected
  def value(op)
    raise "Option '#{op}' not accepted" if !accepts? op
    raise "Option '#{op}' not specified" if !has? op
    return @options[op].value
  end

  # Get the remaining values in ARGV that were not options (ie. did not start
  # with a hyphen).
  def params
    return @params
  end

  # Get all the options given.
  # - Returns an array of option strings.
  # - Call value() to get the corresponding values.
  def options
    ops = {}
    @options.each_value do |data|
      if data.given?
        if !data.short_name.nil?
          ops[data.short_name] = nil
        else
          ops[data.long_name] = nil
        end
      end
    end
    return ops.keys
  end

  # Test function
  # TODO - remove this later!
  def self.test
    begin
      cmdline = CommandLine.new
      cmdline.option("h,help")
      cmdline.option("verbose")
      cmdline.option("f", true)
      cmdline.option('2', true)
      cmdline.option('cool', true)
      
      cmdline.parse(ARGV)
      
      puts "Params: " + cmdline.params.to_s
      cmdline.params.each do |x|
        puts "  #{x}"
      end
      
      puts "Options: "
      cmdline.options.each do |op|
        val = cmdline.value(op)
        print "  #{op}"
        print " = #{val}" if !val.nil?
        print "\n"
      end
      
    rescue => e
      puts "ERROR: " + e.message
    end
  end
  
end
