require 'rubygems'
require 'twitter'
require 'ap'

class Retwitter

	# Initializes the object with the account data
	# === Parameters
	# * *account_data* +Hash+, { username => { consumer_key, consumer_secret, oauth_key, oauth_secret } }
  def initialize account_data
		data = account_data.to_a.first
		@account = { :name => data[0], :data => data[1] }
  end

	# search for search_for terms and retweets everything that's found since last check and is not from this own account, neither direct replies
	# === Parameters
	# * *search_for* +Array+, search terms to be retweeted
  def retweet search_for
		last_verified = File.open 'last_verified', 'r+'
		last_id = last_verified.read.gsub("\000", '')
		last_id = 0 if last_id.empty?
		search_terms = search_for.join ' OR '
		tweets = Twitter::Search.new.containing(search_terms).since_id(last_id).not_from(@account[:name]).not_from('StrikeRH1').fetch.collect do |t|
			t.id unless t.text[0,1] == '@'
		end.compact

		if tweets.length > 0
			twitter = get_twitter_client
			tweets.each do |id|
				begin
					twitter.retweet id
				rescue Twitter::Forbidden
				end
			end
			last_verified.truncate 0
			last_verified.write tweets[0]
		end
  end

  private

  # Configures the Twitter Client and returns a new instance of it, based on @account
  def get_twitter_client
    Twitter.configure do |c|
      c.consumer_key       = @account[:data]['consumer_key']
      c.consumer_secret    = @account[:data]['consumer_secret']
      c.oauth_token        = @account[:data]['oauth_key']
      c.oauth_token_secret = @account[:data]['oauth_secret']
    end
    Twitter::Client.new
  end
end
