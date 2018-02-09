ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require "rubygems"
require 'bundler/setup'
require 'open-uri'
Bundler.require

index = Nokogiri::HTML(open('http://infocouncil.aucklandcouncil.govt.nz/'))
tweetable_items = []

if index.blank? == false
	if not Dir.exist?("#{Dir.pwd}/meetings")
		`mkdir #{Dir.pwd}/meetings`
	end
	
	meetings = []
	
	index.css('.bpsGridMenuItem').each do |link|
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
		addendum = false
		#puts item[2].css("a")
		if item[2].css("a")[0].content.include?("	Addendum")
			##As far as I know there can only be an addendum to an aggenda and not minutes. However if this does happen in the future I would be happy to add as required
			addendum = true
		end
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
	puts tweetable_items
end