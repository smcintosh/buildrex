require 'date'
require 'digest/md5'

$commit_number = 0

SRC = 0
BLD = 1
RAF = 2

# Mix-in for awkward character removal
class String
 def remove_non_ascii(replacement="_") 
   self.gsub(/[\x80-\xff]/,replacement)
 end
end

# Mix-in to switch from DateTime to Time
class Date
  def to_gm_time
    to_time(new_offset, :gm)
  end

  def to_local_time
    to_time(new_offset(DateTime.now.offset-offset), :local)
  end

  private
  def to_time(dest, method)
    #Convert a fraction of a day to a number of microseconds
    usec = (dest.sec_fraction * 60 * 60 * 24 * (10**6)).to_i
    Time.send(method, dest.year, dest.month, dest.day, dest.hour, dest.min,
              dest.sec, usec)
  end
end

# A class that represents a commit transaction.
class Commit
	@categories
	@authName
	@authDate
	@cmtrName
	@cmtrDate
	@msg
	@number
	@fileList

	# Create a new commit by specifying the metadata and filetype categories
	def initialize(authName, authDate, cmtrName, cmtrDate, msg, categs)
		@authName = authName.strip
		@authDate = authDate.strip
		@cmtrName = cmtrName.strip
		@cmtrDate = cmtrDate.strip
		@msg = msg.strip
		@fileList = Hash.new()
		@categories = categs

		$commit_number += 1
		@number = $commit_number
	end

	# Add a modified file to the commit object
	def add_file(fname, action)
		type = -1
		for i in 0..@categories.size-1
			if( @categories[i].has_file(fname) )
				type = i
				break
			end
		end

		@fileList[fname] = [type, action]
	end

	def auth_name()
		name = @authName.gsub(",", "-").gsub(" ", "_").gsub("@", "_").gsub(".", "_").gsub("'", "_").gsub("%","_").gsub("\\","_").gsub("\"", "_")
		name = "empty_name" if( name.empty? )
		return name
	end

	def auth_date()
		return @authDate
	end

	def cmtr_name()
		name = @cmtrName.gsub(",", "-").gsub(" ", "_").gsub("@", "_").gsub(".", "_").gsub("'", "_").gsub("%","_").gsub("\\","_").gsub("\"", "_")
		name = "empty_name" if( name.empty? )
		return name
	end

	def cmtr_date()
		return @cmtrDate
	end

	def filelist
		return @fileList
	end

	def number
		return @number
	end

	def message
		return @msg
	end

	def init_date()
		# Prepare the date string...
		tokens = @cmtrDate.split
		tz = tokens.pop
		year = tokens.pop
		tokens.push(tz)
		tokens.push(year)

		# Generate the date in one timezone
		d = DateTime.parse(tokens.join(" ")).new_offset()

		return d
	end

	def get_year()
		d = init_date()
		return "#{d.year}"
	end

	def get_month()
		d = init_date()
		month = d.month
		month = "0#{d.month}" if( d.month < 10 )
		return "#{d.year}-#{month}"
	end

	def get_month_number()
		d = init_date()
		return d.month
	end

	def get_day()
		d = init_date()
		return "#{d.mday}-#{DateTime::MONTHNAMES[d.month]}-#{d.year}"
	end

	def get_day_number()
		d = init_date()
		return d.mday
	end

	def get_date_string()
		d = init_date()
		return "#{d.year},#{d.month},#{d.mday},#{d.hour},#{d.min},#{d.sec}"
	end

	def get_quarter()
		d = init_date()
		mon = d.month

		return 1 if( mon <= 3 )
		return 2 if( mon > 3 and mon <= 6 )
		return 3 if( mon > 6 and mon <= 9 )
		return 4 if( mon > 9 and mon <= 12 )

		STDERR.puts "ERROR: Execution shouldn't reach here ever..."
	end

	def touches?(cat_idx)
		rtn = false

		@fileList.each do |f, a|
			if( a[0] == cat_idx )
				rtn = true
				break
			end
		end

		return rtn
	end

	def update_file_lists(svn,
		modSrc, src, delSrc,
		modBld, bld, delBld,
		modRest, rest, delRest)
		@fileList.each do |f, a|
			if( a[0] == 0 )
				mod = modSrc
				ovrall = src
				del = delSrc
			elsif( a[0] == 1 or a[0] == 2 or a[0] == 3 )
				mod = modBld
				ovrall = bld
				del = delBld
			else
				mod = modRest
				ovrall = rest
				del = delRest
			end

			case a[1][2]
			when 0
				mod.add(f)
				ovrall.add(f)
			when 1
				mod.add(f)
				del.add(f)

				# hack for sketchy kde data
				ovrall.add(f)

				del_all_children(f, src, bld, rest,
					modSrc, modBld, modRest,
					delSrc, delBld, delRest) if (
					svn and is_dir(f) )
			when (2 or 3)
				mod.add(f)

				# hack for sketchy kde data
				ovrall.add(f)
			end
		end
	end

	def is_dir(f)
		return !@categories[RAF].has_file(f)
	end

	def del_all_children(f, src, bld, rest, modSrc, modBld, modRest, delSrc, delBld, delRest)
		src.each do |file|

			if( file.index(f) != nil )
				src.add(file)
				modSrc.add(file)
				delSrc.add(file)
			end
		end

		bld.each do |file|
			if( file.index(f) != nil )
				bld.add(file)
				modBld.add(file)
				delBld.add(file)
			end
		end

		rest.each do |file|
			if( file.index(f) != nil )
				rest.add(file)
				modRest.add(file)
				delRest.add(file)
			end
		end
	end

	def update_touch_lists(data)
		src_added = false
		src_removed = false
		src_modded = false
		src_changed = false
		bld_added = false
		bld_removed = false
		bld_modded = false
		bld_changed = false

		@fileList.each do |f, a|
			if( a[0] == SRC )
				src_added = (a[1] == "A")
				src_removed = (a[1] == "D")
				src_modded = (a[1] == "M")
				src_changed = true if( !src_changed )
			end

			if( a[0] == 1 or a[0] == 2 or a[0] == 3 )
				bld_added = (a[1] == "A")
				bld_removed = (a[1] == "D")
				bld_modded = (a[1] == "M")
				bld_changed = true if( !bld_changed )
			end
		end

		if( src_added )
			data[0] += 1 if( bld_changed )
			data[1] += 1
		end

		if( src_removed )
			data[2] += 1 if( bld_changed )
			data[3] += 1
		end

		if( src_modded )
			data[4] += 1 if( bld_changed )
			data[5] += 1
		end

		if( bld_added )
			data[6] += 1 if( src_changed )
			data[7] += 1
		end

		if( bld_removed )
			data[8] += 1 if( src_changed )
			data[9] += 1
		end

		if( bld_modded )
			data[10] += 1 if( src_changed )
			data[11] += 1
		end
	end

	def source?(ext)
		return( ext == "c" or
			ext == "C" or
			ext == "cpp" or
			ext == "cc" or
			ext == "cxx" or
			ext == "y" or
			ext == "java" )
	end

	def score()
		scores = [0, 0]
		@fileList.each do |f, a|
			if( a[0] != -1 )
				scores[a[0]] += 1
			end
		end

		return scores
	end

	def get_iso_date(date = @authDate)
		d = DateTime.parse(date)

		return d.to_s
	end

	def get_weka_date(date = @authDate)
		d = DateTime.parse(date)

		rtn = d.year.to_s << "-"

		if( d.mon < 10 )
			rtn << "0"
		end
		rtn << d.mon.to_s << "-"

		if( d.day < 10 )
			rtn << "0"
		end
		rtn << d.day.to_s << "T"

		if( d.hour < 10 )
			rtn << "0"
		end
		rtn << d.hour.to_s << ":"

		if( d.min < 10 )
			rtn << "0"
		end
		rtn << d.min.to_s << ":"

		if( d.sec < 10 )
			rtn << "0"
		end
		rtn << d.sec.to_s

		return rtn
	end

	def print()
		puts @categories
		puts @authName
		puts @authDate
		puts @cmtrName
		puts @cmtrDate
		puts @number
		@fileList.each do |f|
			puts f
		end
	end

	def print_sig(allFiles)
		for i in 0..allFiles.size()-2
			if( @fileList.has_key?(allFiles[i]) )
				print "#{POSITIVE},"
			else
				print "#{NEGATIVE},"
			end
		end

		if( @fileList.has_key?(allFiles.last) )
			puts POSITIVE
		else
			puts NEGATIVE
		end
	end

	def update_sigs(fsigs)
		@fileList.each do |fname, a|
			if( fsigs.has_key?(fname) )
				sig = fsigs[fname]
			else
				sig = FileSignature.new()
			end

			type = "none"
			case a[0]
			when 0
				type = "test"
			when 1
				type = "bld"
			end

			sig.add_commit(@number, get_iso_date(), type,
				a[1])

			fsigs[fname] = sig
		end
	end

	def each_file()
		@fileList.each do |k, v|
			yield k, v
		end
	end

	def print_patches()
		each_file do |fname, mdata|
			puts fname
			puts @msg
			mdata[1][5].print
			puts "-_-_-_-_-"
		end

		puts "____----____----____----"
	end

	def get_bug_id_mozilla()
		tokens = @msg.gsub("#", "").split

		bugid = tokens[1].to_i

		if( bugid < 10000 )
			tokens.size.times do |i|
				begin
					if( tokens[i].casecmp("bugzilla") == 0 )
						bugid = tokens[i+2].to_i
						break
					elsif( tokens[i].casecmp("bug") == 0 )
						bugid = tokens[i+1].to_i
						break
					end
				rescue
					break
				end
			end
		end

		tokens = nil

		return bugid
	end

	def get_bug_id_eclipse()
		loc = @msg =~ /1G/
		return @msg[loc,7] if( loc )

		tokens = @msg.gsub("#", "").gsub(":", " ").split

		bugid = tokens[0]
		return bugid.to_i if( bugid.to_i > 1500 and bugid.to_i < 20000000 )

		bugid = tokens[1]
		return bugid.to_i if( bugid.to_i > 1500 and bugid.to_i < 20000000 )

		bugid = tokens[2]
		return bugid.to_i if( bugid.to_i > 1500 and bugid.to_i < 20000000 )

		tokens.size.times do |i|
			begin
				if( tokens[i].casecmp("bug") )
					bugid = tokens[i+1]
					return bugid.to_i if( bugid.to_i > 1500 and
						bugid.to_i < 20000000 )
				elsif( tokens[i].casecmp("fix") )
					bugid = tokens[i+2]
					return bugid.to_i if( bugid.to_i > 1500 and
						bugid.to_i < 20000000 )
				end
			rescue
				break
			end
		end

		#STDERR.puts(@msg)
		return ""
	end

	def get_cmtr_id_hash()
		return Digest::MD5.hexdigest("#{@msg}#{@cmtrName}")
	end

	def get_auth_id_hash()
		return Digest::MD5.hexdigest("#{@msg}#{@authName}")
	end

	def update_with( other_commit )
		other_commit.each_file do |fname, action|
			if( @fileList[fname] )
				combined = @fileList[fname]

				combined[1][0] = combined[1][0] + action[1][0]
				combined[1][1] = combined[1][1] + action[1][1]
				combined[1][3] = combined[1][3] + action[1][3]
				combined[1][4] = combined[1][4] + action[1][4]

				@fileList[fname] = combined
			else
				add_file(fname, action[1])
			end

			unless( self.newer?(other_commit) )
				@authDate = other_commit.auth_date
				@cmtrDate = other_commit.cmtr_date
			end
		end
	end

	def newer?( other_commit )
		return( (other_commit.init_date <=> self.init_date) == 1 )
	end

	def in_time_window?( other_commit )
		rtn = false
		thisdate = self.init_date.to_gm_time.to_i
		otherdate = other_commit.init_date.to_gm_time.to_i

		return( (thisdate - otherdate).abs <= 300 )
	end
end
