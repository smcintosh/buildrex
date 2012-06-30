require 'set'

class FileCategory
	@fileListing

	def initialize(filename)
		@fileListing = Set.new()
		add_files(filename)
	end

	def add_files(filename)
		listfile = File.new(filename, "r")
		listfile.each_line do |line|
			@fileListing.add(line.strip)
		end
	end


	def has_file(name)
		return @fileListing.include?(name)
	end

	def print(outfile)
		@fileListing.each do |f|
			outfile.puts f
		end
	end
end