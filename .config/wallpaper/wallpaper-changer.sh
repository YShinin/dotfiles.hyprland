#!/usr/bin/env bash

default_wd="$HOME/.config/wallpaper/"
default_cd="$HOME/.cache/wallpaper-changer/"

while [[ -n "$1" ]]; do
  case "$1" in
    -wd | --wallpaper-directory)
      shift
      wallpaper_directory="$1"
      shift
      ;;
    -cd | --cache-directory)
      shift
      cache_directory="$1"
      shift
      ;;
    -h | --help)
      echo "Usage: $(basename "$0") [args]
      -h  | --help    Show this menu
      
      -wd | --wallpaper-directory    Pass there your wallpaper folder 
          (default = ${default_wd})
          
      -cd | --cache-directory    Pass there your path to cache directory used for keeping image previews
          (default = ${default_cd})"
      exit
      ;;
    *)
      echo "Unexpected argument: ${1}. Use -h or --help for more information."
      exit 1
      ;;
  esac
done

if [[ -z $wallpaper_directory ]]; then
  wallpaper_directory=${default_wd}
fi

if [[ ! (-d $wallpaper_directory) ]]; then
  echo "${wallpaper_directory} doesn't exist"
  exit 3
fi

ls_result=$(ls *.png *.jpg)


if [[ -z ls_result ]]; then
  echo "$(wallpaper_directory) has no image files"
  exit 4
fi

# if [[ ! ( -d )]]

for output in $ls_result
do
  ls_basename_list+=$(basename -s .* "$output")"|"
done

ls_basename_list[-1]=$(basename -s '|' "$ls_basename_list")

chosen_image=$(echo "$ls_basename_list" | rofi -sep "|" -dmenu)

echo "$chosen_image"
