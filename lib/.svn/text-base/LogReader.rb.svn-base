require 'Patch.rb'

NEW = 0
DEL = 1
MOD = 2
REN = 3

class LogReader
	@logfile
	@categs

	def initialize(logfile, categs)
		@logfile = logfile
		@categs = categs
	end

	def get_commit()
		puts "Stub"
	end

	def each_commit()
		# peel off the first 'seperator'
		@logfile.gets

		while( (commit = get_commit()) )
			yield commit
		end

		@logfile.close
	end
end

class GitLogReader < LogReader
	def header(first)
		commit = Commit.new(first,
			@logfile.gets(),
			@logfile.gets(),
			@logfile.gets(),
			@logfile.gets(),
			@categs)

		# peel off "Files:" line

		@logfile.gets()

		return commit
	end

	def get_commit()
		first = @logfile.gets()

		return nil if( !first )

		commit = header(first)

		while( (fline = @logfile.gets()) )
			fline = fline.strip
			action, fname = fline.split("\t")
			if( fline == "-^^^--^-" )
				break
			elsif( !fname )
				# peel off the separator
				@logfile.gets()
				break
			end

			commit.add_file(fname, action)
		end

		return commit
	end
end

class GitDiffLogReader < GitLogReader
	def get_commit()
		first = @logfile.gets()

		return nil if( !first )

		commit = header(first)

		while( (fline = @logfile.gets()) )
			fline = fline.strip
			alines, rlines, fname = fline.split("\t")
			if( fline == "-^^^--^-" )
				break
			elsif( !fname )
				# peel off the separator
				@logfile.gets()
				break
			end

			commit.add_file(fname, [alines.to_i, rlines.to_i])
		end

		return commit
	end
end

class GitPatchLogReader < GitLogReader
	def read_patch(patch)
		rtn = true

		type = MOD
		while( (fline = @logfile.gets()) )
			fline = fline.strip
			if( fline == "-^^^--^-" )
				return false
			end

			if( fline[0..5] == "rename" )
				type = REN
			elsif( fline[0..2] == "new" )
				type = NEW
			elsif( fline[0..6] == "deleted" )
				type = DEL
			end

			if( type == DEL and fline[0..2] == "---" )
				@logfile.gets() #remove +++ line
				break
			end

			break if( fline[0..2] == "+++" )
		end

		patch.set_type(type)

		return false if( !fline )

		patch.set_name(fline[6..fline.size-1].strip)

		while( (fline = @logfile.gets()) )
			fline = fline.strip

			if( fline == "-^^^--^-" )
				rtn = false
				break
			elsif( fline[0..3] == "diff" )
				break
			end

			patch.newline(fline)
		end

		return (rtn and fline != nil)
	end

	def get_commit()
		first = @logfile.gets()

		return nil if( !first )

		commit = header(first)

		sums = [0, 0]

		begin
			patch = Patch.new()
			cont = read_patch(patch)
			commit.add_file(patch.name,
				[patch.added_line_count(), patch.del_line_count(),
					patch.type(), patch.churned_incs(),
					patch.churned_ifdefs(), patch])
		end while( cont )

		return commit
	end
end

class SvnLogReader < LogReader
	def get_commit(reverse=true)
		if( reverse )
			res = commit_old_to_new()
		else
			res = commit_new_to_old()
		end
	end

	def commit_old_to_new()
		return nil if ( !(first = @logfile.gets) )

		scrape = [first]

		while( (line = @logfile.gets()) and
				line.strip != "Changed paths:" )
			scrape.push(line.strip)
		end

		return nil if( !line )

		line = @logfile.gets
		tokens = line.strip.split(" | ")
		name, date = tokens[1], tokens[2][0,25]

		commit = Commit.new(name, date, name, date, "", @categs)

		# Pop off the log message
		tokens.last.to_i.times do |i|
			scrape.shift
		end

		while( scrape.size > 0 )
			action, fname = scrape.shift.split
			commit.add_file(fname, action)
		end

		# Peel off separator
		@logfile.gets

		return commit
	end

	def commit_new_to_old()
		first = @logfile.gets()

		return nil if( !first )

		tokens = first.split(" | ")
		name, date = tokens[1], tokens[2][0,25]

		commit = Commit.new(name, date, name, date, @categs)

		# throw away "Changed paths:"
		@logfile.gets()

		while( (fline = @logfile.gets()) )
			fline = fline.strip
			action, fname = fline.split
			if( !fname )
				tokens.last.to_i.times do |i|
					@logfile.gets()
				end

				break
			end

			commit.add_file(fname, action)
		end

		return commit
	end
end

#
# Factories for building log readers
#
class FileLogReaderFactory
	def build_log_reader(logfile, categories, svn=false)
		if( svn )
			rtn = SvnLogReader.new(logfile, categories)
		else
			rtn = GitLogReader.new(logfile, categories)
		end

		return rtn
	end
end

class DiffLogReaderFactory
	def build_log_reader(logfile, categories, svn=false)
		if( svn )
			STDERR.puts "STUB"
		else
			rtn = GitDiffLogReader.new(logfile, categories)
		end

		return rtn
	end
end

class PatchLogReaderFactory
	def build_log_reader(logfile, categories, svn=false)
		if( svn )
			STDERR.puts "STUB"
		else
			rtn = GitPatchLogReader.new(logfile, categories)
		end

		return rtn
	end
end
