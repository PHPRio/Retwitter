require 'rubygems'
require 'twitter'
require 'yaml'
require 'ap'

class Twitrends

  def accounts_file= path
    if File.file?(path) and File.readable?(path)
      @accounts_file = path
      @accounts = YAML::load_file path
    else
      raise ArgumentError, "accounts_file '#{path}' is not readable!"
    end
  end

  def initialize accounts_file_path, verbose = false
    self.accounts_file= accounts_file_path
    @verbose = verbose
    @format = '[%s] %s' # [time] Trending topics
    @start = Time.now
  end

  # If the argument is false or not set, won't tweet. Only show output to know it's working properly.
  def tweet for_real = false
    @accounts.each_pair do |title, acc_data|
      print "Getting Trending Topics and tweeting to #{title}..." if @verbose

      @twitter = get_twitter_client acc_data

      trends = get_trends acc_data['woeid']
      if trends.length == 10
        puts (!@verbose)? 'OK for '+title : ''
      elsif trends.length != 0
        puts (!@verbose)? "Something is wrong with the trends for #{title}: "+trends.inspect : ''
      elsif trends.length == 0
        puts "Looks like there are no trends. =( Exiting..."
        return false
      end

      send_tweets trends, for_real

      puts '' if @verbose
    end
  end

  private

  # Configures the Twitter Client and returns a new instance of it
  def get_twitter_client acc_data
    Twitter.configure do |c|
      c.consumer_key       = acc_data['consumer_key']
      c.consumer_secret    = acc_data['consumer_secret']
      c.oauth_token        = acc_data['oauth_key']
      c.oauth_token_secret = acc_data['oauth_secret']
    end

    Twitter::Client.new
  end

  # Returns the trends for the location of the woeid given (Where On Earth ID).
  # A list of places and codes can be obtained from Twitter::Client#trend_location
  def get_trends woeid
    trends = ''
    got_error = false
    while trends.empty? and (Time.now - @start) < 60 * 15 do # gives up after 15 minutes
      begin
        print 'Trying to connect again. ' if got_error
        trends = @twitter.local_trends woeid
      rescue SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET => e
        puts (@verbose)? ' Oops! Are you connected ('+e.class.to_s+')? Trying again in 10 seconds.' : e.class.to_s
        got_error = true
        sleep 10
      end
    end

    trends
  end

  # Will tweet the trends given (preferably an Array of 10 elements) if the second argument is true;
  # if it's false, will only pretend to tweet, to show it's working (or not)
  def send_tweets trends, for_real
    now  = Time.now
    time = now.hour.to_s+'h'+('%02d'%now.min)
		@@part = 0

    [trends[5..9], trends[0..4]].each do |trends_part|
			max_length = 50
			begin
				tweet = make_tweet time, trends_part, max_length
				max_length = max_length - 2
				puts 'giant tweet, will need to make it again...' if (!for_real && @verbose && tweet.length > 140)
			end while tweet.length > 140

      if for_real
        if tweet.length > 140
					@twitter.update "d igorgsantos Tweet for XX over 140 chars (#{tweet.length})! \"#{tweet[0..50]}\""
					puts "GIANT TWEET! (#{tweet.length} chars) >> "+tweet
				else
	        @twitter.update tweet
				end
      else
        puts "Tweet (#{tweet.length} chars) >> "+tweet if @verbose
      end
    end
  end

	def make_tweet time, trends, max_length
		@@part = @@part + 1

		start = (@@part == 2)? 5 : 0
		trends_concat = trends.collect do |trend|
			i = trends.index(trend) + start + 1
			trend = trend[0..(max_length-4)]+'(..)' if (trend.length > max_length)
			"#{i.to_s}. #{trend}"
		end.join(' || ')
		@format % [time, trends_concat]
	end

end