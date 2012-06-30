# Include the files under the lib directory.
$: << File.expand_path(File.dirname(__FILE__) + "/lib")

require 'FileSignature.rb'
require 'FileCategory.rb'
require 'Commit.rb'
require 'LogReader.rb'
require 'LocBucket.rb'

require 'set'

#
# Program begins here
#
categories = Array.new()

#
# Open the configuration file
#
begin
	categflist = File.new(ARGV[0])
rescue
	STDERR.puts("ERROR: Failed to open category list file")
	exit 1
end

begin
	logfile = File.new(ARGV[1])
rescue
	STDERR.puts("ERROR: Failed to open log file")
	exit 1
end

# Read all the categories from the listing file
categflist.each_line do |line|
	category = FileCategory.new(line.strip)
	categories.push(category)
end

# Log reader factory initialization
lrFactory = PatchLogReaderFactory.new()

logReader = lrFactory.build_log_reader(logfile, categories)
types = Set.new()

logReader.each_commit do |commit|
	commit.each_file do |file, mdata|
		type = mdata[0]
		next if( type == -1 )

		types.add(type)
	end

	if( !types.include?(0) and
		(types.include?(1) or types.include?(2) or types.include?(3))
	)
		commit.print_patches
	end

	types.clear()
end
