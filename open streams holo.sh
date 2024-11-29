#!/usr/bin/sh
sloc="$HOME/.local/share/streamonline"
count=0
rm "$sloc/openstreamsh.txt"
rm "$sloc/openstreamsh.txt"
alias streamonline='bash /home/usr_40476/Projects/streamOnline/streamonline.sh'
function dothething() {
  streamers=( 'LinusTechTips' 'holoen_raorapanthera' 'FUWAMOCOch' 'NerissaRavencroft' 'HakosBaelz' )
  for i in "${streamers[@]}"; do
    (( count++ ))
    streamonline -c $i -s "https://youtube.com/@" >> "$sloc/openstreamsh.txt"
    current="$(sed "$count!d" "$sloc/openstreamsh.txt")"
    echo -e $current
    if [[ $current == *"online"* ]]; then
      online_streamers+=("$i")
    fi
  done
  echo "-----------------"
  if [ -z "${online_streamers}" ]; then
    echo -e "\033[0;31mnobody is online\033[0m"
  else
    echo -e "$online_streamers"
    echo "-----------------"
    for i in "${online_streamers[@]}"; do
      streamlink --title "{author} - {category} - {title}" "https://youtube.com/@$i" $1
    done
  fi
}


printf "(1) automatic (timeout active)\n(2) Choose stream\n(3) exit\n>>> "
read -t 10 action

if [ $? \> 128 ]; then
  printf "\ntimeout exceeded! proceeding automatically!\n" && dothething $1
elif [ $action -eq 1 ]; then
  printf "enter quality\n>>> "
  read -t 10 qlty
  if [ -z $qlty ]; then
    printf "\n" && dothething $1
  else
    printf "\n" && dothething $qlty
  fi
elif [ $action -eq 2 ]; then
  printf "\nEnter twitch handle :\n>>> "
  read -t 10 manuallyChosenStreamer
  streamlink --title "{author} - {category} - {title}" "https://youtube.com/@$manuallyChosenStreamer" $1
  if [ $? \> 128 ]; then exit; fi
fi


rm "$sloc/openstreamsh.txt"
rm "$sloc/openstreamsh.txt"