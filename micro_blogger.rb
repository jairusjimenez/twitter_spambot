require 'jumpstart_auth'
require 'bitly'
require 'klout'


class MicroBlogger
	attr_reader :client

	def initialize
		puts "Initializing..."
		@client = JumpstartAuth.twitter

		@followers_list = nil

		Bitly.use_api_version_3

	end

	def tweet(message)
		if message.length > 140
			puts "Message is longer than 140 characters. I suggest that you don't post it"
		else
			@client.update(message)
		end
	end

	def followers_list
	  unless @followers_list
	    @followers_list = @client.followers.map {|f| @client.user(f).screen_name}
	  end
	  @followers_list
	end

	def spam_my_followers(message)
		followers_list
		@followers_list.each do |x|
			dm(x, message)
		end
	end

	def everyones_last_tweet
		puts "----------------------------"
		friends = @client.friends.collect {|friend| @client.user(friend)}
		friends.sort_by {|friend| friend.screen_name}
		friends.each do |friend|
		  puts "Result #{friend.id}"
		  puts "Name #{friend.name}"
		  timestamp = friend.status.created_at
		  puts "#{friend.screen_name} said this #{friend.status.text} on #{timestamp.strftime("%A, %b %d")}..."
		  puts ""
	  end
	end

	def klout_score
		puts "Klout Scores: "
		Klout.api_key = "xu9ztgnacmjx3bu82warbr3h"
		screen_names = @client.friends.collect { |follower| @client.user(follower).screen_name }
		screen_names.each do |name|
			identity = Klout::Identity.find_by_screen_name(name)
			user = Klout::User.new(identity.id)
			puts "#{name}'s Klout score is #{user.score.score}"
			puts "\n"
		end
	end

	def shorten(original_url)
		puts "Shortening this URL: #{original_url}"
		shortened_url = Bitly.new('hungryacademy', 'R_430e9f62250186d2612cca76eee2dbc6')
		return shortened_url.shorten(original_url).short_url
	end

	def run
		puts "Welcome to the JSL Twitter Client!"
		command = ""
		while command != "q"
			printf "Enter command: "
			input = gets.chomp
			parts = input.split(" ")
			command = parts[0]
			case command
				when 'q' then puts "Goodbye!"
				when 't' then tweet(parts[1..-1].join(" "))
				when 'dm' then dm(parts[1], parts[2..-1].join(" "))
				when 'spam' then spam_my_followers(parts[1..-1].join(" "))
				when 'last' then everyones_last_tweet
				when 's' then shorten(parts[1..-1].join(" "))
				when 'turl' then tweet(parts[1..-2].join(" ") + " " + shorten(parts[-1]))
				when 'k' then klout_score
					
				else
					puts "Sorry, I don't know how to #{command}"
			end
		end
	end

	def dm(target, message)
		if followers_list.include? target
			puts "Trying to send #{target} this direct message:"
			puts message
			tweet("d @#{target} #{message}")
		else
			puts "Target is not in your follower list"
		end

	end

end

blogger = MicroBlogger.new
blogger.run
