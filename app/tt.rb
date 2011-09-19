verbose = ARGV.any? { |v| v == '-v' || v == '--verbose' }

if (ARGV.any? { |v| v == '-t' })
	for_real = true
	puts "[#{Time.now}] Tweeting for real. If I should't do that, CTRL+C NOW! And then, run me again without -t flag, you bastard."
else
	for_real = false
	puts "Entering debug mode (a.k.a. won't tweet for real). If you want to tweet, use -t flag and be happy."
end

require 'Twitrends'

twitrends = Twitrends.new 'accounts.yaml', verbose
twitrends.tweet for_real
