require 'json'
require 'time'

# file handle
file = File.read('scan-times.json')

# parse data from file as json
data_hash = JSON.parse(file)

fastestScan = nil

data_hash.each { |x| 
	node_id = x['node_id']
	#puts node_id
	startTime = Time.parse(x['start'])
	endTime = Time.parse(x['end'])
	elapsed_seconds = endTime - startTime

	#puts elapsed_seconds
	if fastestScan != nil and elapsed_seconds < fastestScan
		fastestScan = node_id
	else
		fastestScan = node_id
	end
}

print "Which asset had the fastest scan? How long?"
puts fastestScan
