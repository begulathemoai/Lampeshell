function fish_greeting
    echo -ne '\x1b[38;5;16m'  # Set colour to primary
    echo " _                              _          _ _ "
    echo "| |    __ _ _ __ ___  _ __  ___| |__   ___| | |"
    echo "| |   / _` | '_ ` _ \| '_ \/ __| '_ \ / _ \ | |"
    echo "| |__| (_| | | | | | | |_) \__ \ | | |  __/ | |"
    echo "|_____\__,_|_| |_| |_| .__/|___/_| |_|\___|_|_|"
    echo "                     |_|"
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
