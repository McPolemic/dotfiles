#!/usr/bin/env ruby
require 'sqlite3'
require 'fileutils'

# If there's a first argument, use that for LAST_READ_DATE.
# Otherwise, if it exists, use the value in ~/.config/tiktok_daily/last_read_date.
def last_read_date
  @last_read_date ||= if ARGV[0]
    ARGV[0].to_i
  elsif File.exist?(LAST_READ_DATE_FILE)
    File.read(LAST_READ_DATE_FILE).to_i
  else
    raise "No last read date provided"
  end
end

def download_tiktok(url)
  `yt-dlp "#{url}" -o "~/Downloads/tiktok_daily/%(id)s.%(ext)s"`
  puts "Downloaded #{url}"
end

CONFIG_DIR = File.expand_path("~/.config/tiktok_daily")
LAST_READ_DATE_FILE = File.join(CONFIG_DIR, "last_read_date")

# Open ~/Library/Messages/chat.db
path = File.expand_path("~/Library/Messages/chat.db")
db = SQLite3::Database.new(path)

# Get the max date after last_read_date from the messages table
max_date = db.get_first_value <<~EOF, last_read_date
  SELECT max(message.date)
    FROM message
    JOIN chat_message_join on message.rowid = chat_message_join.message_id
    JOIN chat on chat.rowid = chat_message_join.chat_id
  WHERE chat.display_name = 'Quaranteam TikToks'
    AND message.text LIKE '%tiktok.com%'
    AND message.associated_message_type = 0 -- Basic message (no tapbacks)
    AND message.date > ?
EOF

# Get all messages between last_read_date and max_date
messages = db.execute <<~EOF, last_read_date, max_date
  SELECT message.text
    FROM message
    JOIN chat_message_join on message.rowid = chat_message_join.message_id
    JOIN chat on chat.rowid = chat_message_join.chat_id
  WHERE chat.display_name = 'Quaranteam TikToks'
    AND message.text LIKE '%tiktok.com%'
    AND message.associated_message_type = 0 -- Basic message (no tapbacks)
    AND message.date BETWEEN ? AND ?
  ORDER BY message.date ASC;
EOF

# Print messages
messages.each { download_tiktok(_1.first) }

# When the program is finished running, write the new last_read_date to that location
# (creating directories as necessary)
FileUtils.mkdir_p(CONFIG_DIR)
File.write(LAST_READ_DATE_FILE, max_date)
