# frozen_string_literal: true

require 'open-uri'
require 'dotenv'
Dotenv.load('.local.env', '.env')

VERSION = 'v2.x.x'

def version_string
	if `git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null`
		return `git describe --tags`.chomp
	else
		return VERSION
	end
end

require 'discordrb'

bot = Discordrb::Bot.new token: ENV['DISCORD_TOKEN'], intents: [Discordrb::ALL_INTENTS], name: "Hiroko"

Main_server_id = ENV['DISCORD_SERVER_ID'].to_i
Owner_id = ENV['DISCORD_OWNER_ID'].to_i

New_member_role_id = 961023612826054656

Carmine_emoji = 732037619483017367
Hnid_emoji = 961158545020190741

Bot_channel = 961170758065881088

Bot_version = version_string

#puts "This bot's invite URL is #{bot.invite_url}%20applications.commands."
#puts 'Click on it to invite it to your server.'

bot.ready() do |event|
	puts "Username: #{bot.profile.username}##{bot.profile.discriminator}"
	puts "ID: #{bot.profile.id}"
	puts "In #{bot.servers.length()} servers:"
	bot.servers.each do |id, server|
		puts "#{server.name} (#{server.member_count} members) [#{server.id}]"
	end
	bot.playing = 'Carmine Impact'

end

def is_main_server?(server)
	return server.id == Main_server_id
end

def is_bot_channel?(channel)
	return channel.id == Bot_channel
end

bot.member_join() do |event|
	if is_main_server? event.server
		event.member.add_role(New_member_role_id, 'new member')
	end
end

# add sticker remover when discordrb supports stickers.

bot.mention(contains: 'version') do |event|
	event.respond "`Hiroko #{Bot_version}`"
end

reactions = {
	'matchmaking' => {'message' => 733930572484706334, 'role' => 645008815191883815},
	'social' => {'message' => 789581569294598154, 'role' => 789581012001751070}
}

reactions.each do |_, value|
	bot.reaction_add(emoji: Carmine_emoji, message: value['message']) do |event|
		event.user.add_role(value['role'])
	end

	bot.reaction_remove(emoji: Carmine_emoji, message: value['message']) do |event|
		event.user.remove_role(value['role'])
	end
end


bot.register_application_command(:help, "Display useful information.")

bot.register_application_command(:link, "Link your Discord account to your HNID!")

bot.register_application_command(:quote, "Retrieves a HarpNet quote!", server_id: ENV['DISCORD_SERVER_ID']) do |cmd|
	cmd.integer('id', "ID of the quote to retrieve")
end

bot.application_command(:help) do |event|
	built_embed = Discordrb::Webhooks::Embed.new(
		description: "Nice to meet you! I manage the connections between your HNID and Discord, among other things.",
		title: "Hey! I'm Hiroko, the HarpNet Discord bot!",
		url: "https://hnss.ga/hiroko",
		color: 0xff2400
	)

	built_embed.add_field(
		name: "Linking your HNID",
		value: "If you would like to link your Discord account with your HNID, use the `/link` command for more info!"
	)

	built_embed.footer = Discordrb::Webhooks::EmbedFooter.new(
		text: "Hiroko #{Bot_version} | https://hnss.ga/hiroko",
		icon_url: bot.profile.avatar_url
	)

	event.respond(embeds: [built_embed], ephemeral: !is_bot_channel?(event.channel))
end

account_settings_url = "https://harpnetstudios.com/my/account/settings"

bot.application_command(:link) do |event|
  built_embed = Discordrb::Webhooks::Embed.new(
		description: "To link your Discord account to your HarpNet ID, click the button below!",
		title: "HNID Linking",
		url: account_settings_url,
		color: 0xff2400
	)
	event.respond(content: "", embeds: [built_embed], ephemeral: true) do |_, view|
		view.row do |r|
			r.button(label: 'Link your Discord account!', style: :link, emoji: Hnid_emoji, url: account_settings_url)
		end
	end
end

bot.application_command(:quote) do |event|
	quotes = URI.open('https://raw.githubusercontent.com/HarpNetStudios/HarpNetQuotes/master/quotes.txt') { |f| f.read.split(/\n+/) }
	line = ''

	if event.options['id'] == nil
		line = quotes.sample

		if !event.channel.nsfw?
			while line.chr == '#' # if it's NSFW, reroll
				line = quotes.sample
			end
		end

		if line.chr == '#'
			line = "**#{line[1..-1]}**"
		end
	else
		line = quotes[event.options['id'] - 1] || "quote not found!"
	end
	event.respond(content: line, ephemeral: !is_bot_channel?(event.channel))
end

at_exit { bot.stop }
begin
	bot.run
rescue Interrupt => e
	bot.stop
end
