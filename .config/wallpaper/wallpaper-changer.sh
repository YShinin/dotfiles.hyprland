#!/usr/bin/env bash
# doesnt work with spaces in file names

default_wd="$HOME/.config/wallpaper/"
default_cd="$HOME/.cache/wallpaper-changer/"

while [[ -n "$1" ]]; do
  case "$1" in
    -wd | --wallpaper-directory)
      shift
      wallpaper_directory="$1"
      ;;
    -cd | --cache-directory)
      shift
      cache_directory="$1"
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
  shift
done

if [[ -z $wallpaper_directory ]]; then
  wallpaper_directory=${default_wd}
fi

if [[ ! (-d $wallpaper_directory) ]]; then
  echo "${wallpaper_directory} doesn't exist"
  exit 3
fi

# ^ ANCHER TO THE START OF LINE
# [^.]+ ANY CHARACTER EXCEPT DOR ONE OR MORE TIME
# \. SECURED DOT
# (...)$ ONE OF EXTENTIONS AT THE END
ls_result=$(ls "$wallpaper_directory" | grep -E "^[^.]+\.(png|jpg|webm|jpeg)$")


if [[ -z "$ls_result" ]]; then
  echo "$wallpaper_directory has no image files"
  exit 4
fi

echo "wd - $wallpaper_directory    ls result - $ls_result   ls result len ${#ls_result} "

if [[ -z "$cache_directory" ]]; then
  cache_directory=${default_cd}
fi

if [[ -e "$cache_directory" ]]; then
  if [[ ! ( -d "$cache_directory" ) ]]; then
    echo "$cache_directory exists and it is not a directory"
    exit 5
  fi
else
  mkdir -p "$cache_directory"
fi

chosen_image=$( for image_without_path in $ls_result
do
  image_without_extention=$(basename -s .* "$image_without_path")
  if [[ ! ( -f "${cache_directory}${image_without_path}")]]; then
    magick convert "${wallpaper_directory}${image_without_path}" -resize 300x200 "${cache_directory}${image_without_path}"
  fi
  echo -en "${image_without_extention}\0icon\x1f${cache_directory}${image_without_path}\n"
done | rofi -show-icons -dmenu -no-config )

echo "$chosen_image"
