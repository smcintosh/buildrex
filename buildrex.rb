# Include the files under the lib directory.
$: << File.expand_path(File.dirname(__FILE__) + "/lib")

require 'FileSignature.rb'
require 'FileCategory.rb'
require 'Commit.rb'
require 'LogReader.rb'
require 'LocBucket.rb'

require 'set'

REPO_DUMP = "REPO_DUMP_FILE"
SRC_CATEGORY = "SRC_CATEGORY_FILE"
CONSTRUCTION_CATEGORY = "CONSTRUCTION_CATEGORY_FILE"
CFG_CATEGORY = "CONFIGURATION_CATEGORY_FILE"
SCRIPTS_CATEGORY = "SCRIPTS_CATEGORY_FILE"
TESTS_CATEGORY = "TESTS_CATEGORY_FILE"

#
# Program begins here
#

#
# Read the configuration file
#
begin
	configfile = File.read(ARGV[0])
	config_parms = Hash[configfile.scan(/(\S+)\s*=\s*"([^"]+)/)]
rescue
	STDERR.puts("ERROR: Failed to read configuration file")
	exit 1
end

#
# Open the repository dump file
#
begin
	if config_parms[REPO_DUMP]
		logfile = File.new(config_parms[REPO_DUMP])
	else
		STDERR.puts(
			"ERROR: Missing mandatory parameter '#{REPO_DUMP}'")
	end
rescue
	STDERR.puts("ERROR: Failed to open repository dump file")
	exit 1
end

#
# Read all the categories
#
categories = Array.new()
[SRC_CATEGORY,CONSTRUCTION_CATEGORY,CFG_CATEGORY,SCRIPTS_CATEGORY,TESTS_CATEGORY].each do |category|
	if config_parms[category]
		categories.push(FileCategory.new(config_parms[category]))
	else
		STDERR.puts(
			"ERROR: Missing mandatory parameter '#{category}'")
		exit 1
	end
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
