class FileSignature
	@data
	@type

	def initialize()
		@data = []
	end

	def add_commit(id,date,type,action)
		@type = type
		@data.push([id,date,action])
	end

	def first()
		return @data.first[0]
	end

	def print(outfile)
		for i in 0..@data.size()-2
			outfile.print "#{@data[i][0]},"
		end
		outfile.print @data.last[0]
	end

	def type
		return @type
	end

	def print(outfile, fnum)
		@data.each do |d|
			if( d[2] == "D" )
				outfile.print("bdelb") if( @type == "bld" )
				outfile.print("tdelt") if( @type == "test" )
			else
				outfile.print(@type)
			end
			outfile.puts(",#{d[0]},#{fnum}")
		end
	end

	def print_flat(outfile, fnum)
		@data.each do |d|
			if( d[2] == "D" )
				outfile.puts("3,#{d[0]},#{fnum}")
			else
				outfile.puts("#{@type},#{d[0]},#{fnum}")
			end
		end
	end
end