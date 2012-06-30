class LocBucket
	@churnSignature
	@count

	def initialize(size)
		@churnSignature = Array.new(size, 0)
		@count = 0
	end

	def add_churn(lines)
		return false if( lines.size != @churnSignature.size )

		@churnSignature.each_index do |i|
			@churnSignature[i] += lines[i]
		end

		@count += 1

		return true
	end

	def print(stream)
		@churnSignature.size.times do |i|
			stream.print("#{@churnSignature[i]},")
		end
		stream.puts(@count)
	end
end