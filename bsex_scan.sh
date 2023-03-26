#!/bin/bash

BOTsecret=''
chatid=''

# Get and save mullvad socks5 proxy
curl -s https://api.mullvad.net/www/relays/wireguard/ | jq -r '.[] .socks_name' -> socks5.txt

# Get and save all active exchangers ID
curl -sL api.bestchange.ru/info.zip | funzip - | awk -F';' '{print $1}' | sort | uniq > id.txt

# Read the id.txt file line by line and get all the URLs of the exchangers
cat id.txt | xargs -I {} -P 10 sh -c '
    name="$1"
    # Loop the request until we get a response from the server
    while true; do
        # Using curl to get server response with Mullvad socks5 proxy for each exchange ID
        response=$(curl -sI "https://www.bestchange.ru/click.php?id=$name" -w "%{redirect_url}\n" -o /dev/null --socks5-hostname "$(sort -R socks5.txt | head -n1)")
        # Check the status of the response and display the response if it is received
        if [ $? -eq 0 ]; then
            if [[ -n "$response" ]]; then
                echo "$response"
                break
            else
                # If an empty response is received, then wait 2 seconds and try again
                sleep 2
            fi
        else
            # If the connection to the server failed, wait 2 seconds and try again
            sleep 2
        fi
    done
' sh {} > urls.txt

# Send result to tg_channel
curl -F document=@"./urls.txt" -F caption="BestChange_$(date +'%Y-%m-%d')" "https://api.telegram.org/bot$BOTsecret/sendDocument?chat_id=$chatid" --noproxy '*'
