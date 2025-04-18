#!/usr/bin/env bash

# Usage
#  get_codes.sh [--test] [--newline]
#     --test: Run the script in test mode.
#     --newline: Print a newline after the output.
#  To keep the script simple, the arguments are expected to be in these exact positions.

ROW_REGEX='^\[?\{"ROWID"\:([[:digit:]]+),"sender"\:"([^"]+)","service"\:"([^"]+)","message_date"\:"([^"]+)","text"\:"([[:print:]][^\\]+)"\}.*$'

DEFAULT_MATCH_REGEX='([a-zA-Z0-9]{4,})'

# 正则映射
rules=${regexMap}

# Print the first argument if in Alfred debug mode.
function debug_text() {
	if [[ $alfred_debug == "1" ]]; then
		>&2 echo $1
	fi
}

output=''
lookBackMinutes=${lookBackMinutes:-15}

# Check if alfred has full disk access.
if [[ "$1" != "--ignore-full-disk-check" && ! -r ~/Library/Messages/chat.db ]]; then
	echo '{
	  "items": [
	    {
	      "type": "default",
	      "valid": true,
	      "icon": {"path": "icon.png"},
	      "subtitle": "Launch System Preferences and turn this on.",
	      "title": "Full Disk Access Required for Alfred",
		  "variables": {
			"launch_full_disk": 1
		  }
	    },
	    {
	      "type": "default",
	      "valid": true,
	      "icon": {"path": "icon.png"},
	      "subtitle": "See a short explanation of why full disk access is required.",
	      "title": "Why is full disk access required?",
		  "variables": {
			"launch_url": 1,
			"url": "https://github.com/thebitguru/alfred-simple-2fa-paste/wiki/Full-Disk-Access"
		  }
	    }
	  ]
	}'
	exit 1
fi

debug_text "Lookback minutes: $lookBackMinutes"

if [[ "$2" == "--test" ]]; then
	echo "Running in test mode."
	response=`cat test_messages.txt`
else
	debug_text "Lookback minutes: $lookBackMinutes"

	sqlQuery="select
		message.rowid,
		ifnull(handle.uncanonicalized_id, chat.chat_identifier) AS sender,
		message.service,
		strftime('%H:%M',datetime(message.date / 1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime')) AS message_date,
		message.text
	from
		message
			left join chat_message_join on chat_message_join.message_id = message.ROWID
			left join chat on chat.ROWID = chat_message_join.chat_id
			left join handle on message.handle_id = handle.ROWID
	where
		message.is_from_me = 0
		and message.text is not null
		and length(message.text) > 0
		and message.text regexp '验证码|verification'
		and datetime(message.date / 1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime')
		          >= datetime('now', '-$lookBackMinutes minutes', 'localtime')
	order by
		message.date desc
	limit 5;"
	debug_text "SQL Query: $sqlQuery"

	response=$(sqlite3 ~/Library/Messages/chat.db -json "$sqlQuery" ".exit")
	debug_text "SQL Results: '$response'"
fi


if [[ -z "$response" ]]; then
	output+='{
		"rerun": 1,
		"items": [
			{
				"type": "default",
				"valid": "false",
				"icon": {"path": "icon.png"},
				"arg": "",
				"subtitle": "Searched messages in the last '"$lookBackMinutes"' minutes.",
				"title": "No codes found"
			}
		]
	}'
else
	while read line; do
		debug_text "Line: $line"
		if [[ $line =~ $ROW_REGEX ]]; then
		 	sender=${BASH_REMATCH[2]}
			message_date=${BASH_REMATCH[4]}
			message=${BASH_REMATCH[5]}
			debug_text " Found sender: $sender"
			debug_text " Found message_date: $message_date"
			debug_text " Found message: $message"

			message_quoted=${message//[\"]/\\\"}

		    # 标记是否找到匹配
		    local matched=false
		    # 匹配正则
		    local matchRegex=""

		    # 遍历所有规则
		    for prefix in $(echo "$rules" | sed 's/[{},]//g' | grep -o '"【[^"]*"' | tr -d '"'); do
		        # 提取对应的正则表达式
		        regex=$(echo "$rules" | sed -n "s/.*\"$prefix\": \"\([^\"]*\)\".*/\1/p")
		        # 检查消息是否以特定前缀开头
		        if [[ "$message" == "$prefix"* ]]; then
		            matchRegex="$regex"
		            break
		        fi
		    done

		    # 如果没有匹配到特定规则，使用默认规则
		    if [[ -z "$matchRegex" ]]; then
		        matchRegex=$DEFAULT_MATCH_REGEX
		    fi

		    debug_text "Match regex: '$matchRegex'"

			# 匹配验证码
			if [[ $message =~ $matchRegex ]]; then
				code=${BASH_REMATCH[1]}
				debug_text " -- Message: $message"
				debug_text " -- Found-1 ${code}"
				
				# 拼接选项
				if [[ -z "$output" ]]; then
					output='{"rerun": 1, "items":['
				else
					output+=','
					if [[ "$3" == "--newline" ]]; then
						output+="\n"
					fi
				fi
				item="{\"type\":\"default\", \"icon\": {\"path\": \"icon.png\"}, \"arg\": \"$code\", \"subtitle\": \"${message_quoted}\", \"title\": \"$code\"}"
				output+=$item
			fi
		else
			>&2 echo "No match for $line"
		fi

		continue
	done <<< "$response"
	output+=']}'
fi

debug_text "Final Output: '$output'"
echo -e $output
