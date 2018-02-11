ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require "rubygems"
require 'bundler/setup'
require 'open-uri'
Bundler.require
DAY_ENDINGS = ["", "st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th", "st"]
index = Nokogiri::HTML(open('http://infocouncil.aucklandcouncil.govt.nz/'))
tweetable_items = []

twitter_keys = File.read("#{Dir.pwd}/twitter_api_keys.txt").split("\n")

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = twitter_keys[0]
  config.consumer_secret     = twitter_keys[1]
  config.access_token        = twitter_keys[2]
  config.access_token_secret = twitter_keys[3]
end

if index.blank? == false
	if not Dir.exist?("#{Dir.pwd}/meetings")
		`mkdir #{Dir.pwd}/meetings`
	end

	meetings = []

	index.css('.bpsGridMenuItem', '.bpsGridMenuAltItem').each do |link|
		meetings << [Date.parse(link.css('.bpsGridDate')[0].content), link.css('.bpsGridCommittee')[0].content, link.css('.bpsGridAgenda')[0], link.css('.bpsGridAttachments')[0], link.css('.bpsGridMinutes')[0], link.css('.bpsGridMinutesAttachments')[0]]
	end
	#puts meetings
	meetings.each do |item|
		dated_path = "#{Dir.pwd}/meetings/#{item[0].strftime("%Y-%m-%d")}"
		meeting_path = "#{dated_path}/#{item[1].downcase.gsub(" ", "")}"
		if not Dir.exist?(dated_path)
			`mkdir #{dated_path}`
		end

		##Many local board/pannels are in Maori which has some charaters that wont work with file systems.So we need to replace those charaters them.
		foldername = item[1].downcase.gsub(/[^0-9A-Za-z.\-]/, '_')

		if not File.exist?("#{dated_path}/#{foldername}")
			`mkdir #{dated_path}/#{foldername}`
		end
		##Now that this meeting has been registered we need to tell it what has been uploaded so that we can tweet it out. and save it so that next time we won't tweet the same thing.
		agenda_items = []
		agenda_attachements = []
		minutes = []
		minutes_attachements = []

		changes_to_folder = [item[0], item[1]]

		item[2].css("a").each do |item|
			item_filename = item['href'].split("/").last
			##Has this file already been scrapped
			if not File.exist?("#{dated_path}/#{foldername}/#{item_filename}.item")
				##Write the file so we know its added
				File.open("#{dated_path}/#{foldername}/#{item_filename}.item", 'w') { |file| file.write("") }

				agenda_items << item
			end
		end

		item[3].css("a").each do |item|
			item_filename = item['href'].split("/").last
			##Has this file already been scrapped
			if not File.exist?("#{dated_path}/#{foldername}/#{item_filename}.item")
				##Write the file so we know its added
				File.open("#{dated_path}/#{foldername}/#{item_filename}.item", 'w') { |file| file.write("") }

				agenda_attachements << item
			end
		end

		item[4].css("a").each do |item|
			item_filename = item['href'].split("/").last
			##Has this file already been scrapped
			if not File.exist?("#{dated_path}/#{foldername}/#{item_filename}.item")
				##Write the file so we know its added
				File.open("#{dated_path}/#{foldername}/#{item_filename}.item", 'w') { |file| file.write("") }

				minutes << item
			end
		end
		item[5].css("a").each do |item|
			item_filename = item['href'].split("/").last
			##Has this file already been scrapped
			if not File.exist?("#{dated_path}/#{foldername}/#{item_filename}.item")
				##Write the file so we know its added
				File.open("#{dated_path}/#{foldername}/#{item_filename}.item", 'w') { |file| file.write("") }

				minutes_attachements << item
			end
		end
		changes_to_folder << agenda_items
		changes_to_folder << agenda_attachements
		changes_to_folder << minutes
		changes_to_folder << minutes_attachements

		if agenda_items.count > 0 or agenda_attachements.count > 0 or minutes.count > 0 or minutes_attachements.count > 0
			tweetable_items << changes_to_folder
		end
	end
	 tweetable_items.each do |item|
		 formatted_tweet = []
		 hashtag_types_included = []
		 title_type = []
		 addendum = ""
		 tweet_image = ""
		 if item[2][0].content.include?("Addendum")
			 addendum = " Addendum"
			 hashtag_types_included << "#CouncilAgendaAddendum"
		 else
			 hashtag_types_included << "#CouncilAgenda"
		 end
		 if item[2].count > 0
			 title_type << "Agenda#{addendum}"
		 end
		 if item[3].count > 0
			 title_type << "Agenda#{addendum} Attachments"
		 end
		 if item[4].count > 0
			 title_type << "Minutes"
			 hashtag_types_included << "#CouncilMinutes"
		 end
		 if item[5].count > 0
			 title_type << "Minutes Attachements"
			 hashtag_types_included << "#CouncilMinutes"
		 end
		  formatted_tweet << "#{item[1]} #{title_type.join(" & ")} for the #{item[0].mday}#{DAY_ENDINGS[item[0].mday]} of #{item[0].strftime("%B %Y")}"
		 ##This deals with Agendas
		 if not item[2].count <= 0
			 
			 item[2].each do |url|
				if url['href'].include?(".PDF") or url['href'].include?(".pdf")
			 		formatted_tweet << "Agenda PDF: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
				else
					formatted_tweet << "Agenda HTML: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
					
					agenda = Nokogiri::HTML(open('http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last.gsub("_WEB", "")'))
					agenda_items = []
					
					agenda.css(".TOCCell").each do |item|
					  if not item == nil
					    a = item.content.split("\u00A0")
					    a.delete("")
					    if a[1] != "" && a[1] != nil
					      agenda_items << (a[1]).gsub(/[\r\n]+/, ' ')
					    end
					  end
					end
					puts agenda_items.join("\n")
					if not Dir.exist?("#{Dir.pwd}/images")
						`mkdir #{Dir.pwd}/images`
					end
					`convert -background white -fill navy -pointsize 15 -size 800x caption:'#{agenda_items.join("\n")}' #{Dir.pwd}/images/#{url['href'].split("?URL=").last}.png`
					tweet_image = "#{Dir.pwd}/images/#{url['href'].split("?URL=").last}.png"
				end
			end
		 end
		 ##agenda attachements
		 if not item[3].count <= 0
			 item[3].each do |url|
				 if url['href'].include?(".PDF") or url['href'].include?(".pdf")
					 formatted_tweet << "Attachments PDF: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
				 else
					 formatted_tweet << "Attachments HTML: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
				 end
			 end
		 end
		 ##Miniutes
		 if not item[4].count <= 0
			item[4].each do |url|
				if url['href'].include?(".PDF") or url['href'].include?(".pdf")
			 		formatted_tweet << "Minutes PDF: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
				else
					formatted_tweet << "Minutes HTML: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
				end
			end
		 end
		 ##Miniutes attachements
		 if not item[5].count <= 0
		 item[5].each do |url|
			 if url['href'].include?(".PDF") or url['href'].include?(".pdf")
				 formatted_tweet << "Attachments PDF: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
			 else
				 formatted_tweet << "Attachments HTML: http://infocouncil.aucklandcouncil.govt.nz/#{url['href'].split("?URL=").last}"
			 end
		 end
		end
		 formatted_tweet << "#AucklandCouncil #PublicRecords #{hashtag_types_included.join(" ")}"
		 puts "##Tweet Starts"
		 puts formatted_tweet.join("\n")
		 begin
		 	 if tweet_image == ""
			 	client.update(formatted_tweet.join("\n"))
			 else
			 	client.update_with_media(formatted_tweet.join("\n"), File.new(tweet_image))
			 end
		 rescue => e
			 if e.message.include?("Tweet needs to be a bit shorter")
				 begin
					 if tweet_image == ""
					 	client.update((formatted_tweet.first(formatted_tweet.size - 1)).join("\n"))
					 else
					 	client.update_with_media((formatted_tweet.first(formatted_tweet.size - 1)).join("\n"), File.new(tweet_image))
					 end
				 rescue => e
					 puts e.message
				 end
			 else
				 puts e.message
			 end
		 end
		 puts "##Tweet Ends"
	 end
end
