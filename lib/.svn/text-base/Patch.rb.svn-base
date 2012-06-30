class Patch
	@name
	@type
	@addedLines
	@rmLines
	@otherLines
	@patchRecovery

	def initialize()
		@addedLines = []
		@rmLines = []
		@otherLines = []
		@patchRecovery = []
	end

	def newline(line)
		@patchRecovery.push(line)

		case line[0,1]
		when '+'
			to_mod = @addedLines
		when '-'
			to_mod = @rmLines
		else
			to_mod = @otherLines
		end

		to_mod.push(line[1..line.size-1])
	end

	def set_name(name)
		@name = name
	end

	def set_type(type)
		@type = type
	end

	def name()
		return @name
	end

	def type()
		return @type
	end

	def added_line_count()
		return @addedLines.size
	end

	def del_line_count()
		return @rmLines.size
	end

	def other_line_count()
		return @otherLines.size
	end

	def include?(line)
		return ((line =~ /^#[ \t]*include/) != nil )
	end

	def ifdef?(line)
		return ((line =~ /^#[ \t]*if/) != nil )
	end

	def churned_incs()
		count = 0

		@addedLines.each do |line|
			count += 1 if( include?(line) )
		end

		@rmLines.each do |line|
			count += 1 if( include?(line) )
		end

		return count
	end

	def churned_ifdefs()
		count = 0

		@addedLines.each do |line|
			count += 1 if( ifdef?(line) )
		end

		@rmLines.each do |line|
			count += 1 if( ifdef?(line) )
		end

		return count
	end

	def print()
		@patchRecovery.each do |line|
			puts line
		end
	end
end