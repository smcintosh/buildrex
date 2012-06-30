require 'getoptlong'

def print_help()
	STDERR.puts("USAGE: #{$0} <logfile> <listfile>")
	STDERR.puts
	STDERR.puts("OPTIONS:")
	STDERR.puts
	STDERR.puts("--execute, -e <type>")
	STDERR.puts("\tProduce the given type of output, options are:")
	STDERR.puts("\t1")
	STDERR.puts("\t\tPrint each point as a row of the form")
	STDERR.puts("\t\t(date, category, commit#, file#)")
	STDERR.puts("\t2")
	STDERR.puts("\t\tDebug option to print each file and its")
	STDERR.puts("\t\tcorresponding category (file, category)")
	STDERR.puts("\t3")
	STDERR.puts("\t\tHigh-level build vs. source changes")
	STDERR.puts("\t\t(source changed?, build changed?)")
end

def get_options(opt_array)
	opts = GetoptLong.new(
		['--execute', '-e', GetoptLong::REQUIRED_ARGUMENT],
		['--svn', '-s', GetoptLong::NO_ARGUMENT],
		['--diff-log', '-d', GetoptLong::NO_ARGUMENT],
		['--patch-log', '-p', GetoptLong::NO_ARGUMENT],
		['--bucket-size', '-b', GetoptLong::REQUIRED_ARGUMENT],
		['--eclipse', '-E', GetoptLong::NO_ARGUMENT],
		['--mozilla', '-M', GetoptLong::NO_ARGUMENT],
		['--bug', '-B', GetoptLong::NO_ARGUMENT]
	)

	opts.each do |opt, arg|
		case opt
		when '--execute'
			opt_array[0]= arg.to_i
		when '--svn'
			opt_array[1] = true
		when '--diff-log'
			opt_array[2] = "diff"
		when '--patch-log'
			opt_array[2] = "patch"
		when '--bucket-size'
			opt_array[5] = arg.to_i
		when '--eclipse'
			opt_array[6] = true
		when '--mozilla'
			opt_array[8] = true
		when '--bug'
			opt_array[9] = true
		end
	end

	if( ARGV.size != 2 )
		print_help()
		return false
	end

	pkgfname = ARGV.shift
	opt_array[3] = File.new(pkgfname)
	opt_array[4] = File.new(ARGV.shift)
	opt_array[7] = pkgfname

	return true
end
