#!/usr/bin/env bash
# doesnt work with spaces in file names


if ! command -v magick > /dev/null 2>&1 ; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "Dependences check failed, make sure you have magick in \$PATH"
  exit 1
fi

if ! command -v matugen > /dev/null 2>&1 ; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "Dependences check failed, make sure you have matugen in \$PATH"
  exit 1
fi

if ! command -v wallust > /dev/null 2>&1 ; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "Dependences check failed, make sure you have wallust in \$PATH"
  exit 1
fi

if ! command -v python > /dev/null 2>&1 ; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "Dependences check failed, make sure you have python in \$PATH"
  exit 1
fi

if ! command -v notify-send > /dev/null 2>&1 ; then
  echo "ERROR: Wallpaper changer
  Dependences check failed, make sure you have notify-send function active"
  exit 1
fi

default_wd="$HOME/.config/wallpaper/"
default_cd="$HOME/.cache/wallpaper-changer/"
default_hc="$HOME/.config/hypr/modules/current-wallpaper.conf"
default_kps="$HOME/.config/wallust/kitty-correction.py"
default_kitty_colors_raw="$HOME/.config/kitty/colors-raw.conf"
default_kitty_colors_tweaked="$HOME/.config/kitty/colors-tweaked.conf"

wallpaper_hypr_config=$default_hc
kitty_python_script=$default_kps
kitty_colors_raw=$default_kitty_colors_raw
kitty_colors_tweaked=$default_kitty_colors_tweaked

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
    -hc | --hyprland-config)
      shift
      wallpaper_hypr_config="$1"
      ;;
    -h | --help)
      echo "Usage: $(basename "$0") [args]
      -h  | --help    Show this menu
      
      -wd | --wallpaper-directory    Pass there your wallpaper folder 
          (default = ${default_wd})
          
      -cd | --cache-directory    Pass there your path to cache directory used for keeping image previews
          (default = ${default_cd})
          
      -hc | --hyprland-config    Pass there your path to config file where current wallpaper will be stored
        [NOTE file will be fully cleared after wallpaper change]
          (default = ${default_hc})"
      exit
      ;;
    *)
      notify-send -t 3000 "ERROR: Wallpaper changer" "Unexpected argument: ${1}. Use -h or --help for more information." 
      exit 1
      ;;
  esac
  shift
done

if [[ -z $wallpaper_directory ]]; then
  wallpaper_directory=${default_wd}
fi

if [[ ! (-d $wallpaper_directory) ]]; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "${wallpaper_directory} doesn't exist" 
  exit 3
fi

# ^ ANCHER TO THE START OF LINE
# [^.]+ ANY CHARACTER EXCEPT DOT ONE OR MORE TIME
# \. SECURED DOT
# (...)$ ONE OF THE EXTENTIONS AT THE END
ls_result=$(ls "$wallpaper_directory" | grep -E "^[^.]+\.(png|jpg|webm|jpeg)$")


if [[ -z "$ls_result" ]]; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "$wallpaper_directory has no image files"
  exit 4
fi

# echo "wd - $wallpaper_directory    ls result - $ls_result   ls result len ${#ls_result} "

if [[ -z "$cache_directory" ]]; then
  cache_directory=${default_cd}
fi

if [[ -e "$cache_directory" ]]; then
  if [[ ! ( -d "$cache_directory" ) ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "$cache_directory exists and it is not a directory"
    exit 5
  fi
else
  mkdir -p "$cache_directory"
fi

chosen_image=$( for image_without_path in $ls_result
do
  if [[ ! ( $image_without_path =~ \.(png|jpg|webm|jpeg)$ ) ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "File can't contain white space!"
  fi

  image_without_extention=$(basename -s .* "$image_without_path")
  if [[ ! ( -f "${cache_directory}${image_without_path}")]]; then
    magick "${wallpaper_directory}${image_without_path}" -resize 300x200 "${cache_directory}${image_without_path}"
  fi
  echo -en "${image_without_extention}\0icon\x1f${cache_directory}${image_without_path}\n"
done | rofi -show-icons -dmenu -no-config )

[[ ! -z $chosen_image ]] || exit 0

if [[ ! -f $wallpaper_hypr_config ]]; then
  touch $wallpaper_hypr_config

  if [[ ! $? ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "Coudn't create config file in {$wallpaper_hypr_config}, verify if directory is persent"
    exit 6
  fi
fi

chosen_image=$(echo $ls_result | grep -o $chosen_image)

wallpaper_in_config=$(grep "^\$wallpaper_in_config" "$wallpaper_hypr_config" | sed "s/.*= //" | sed 's/#.*//')

if [[ -z $wallpaper_in_config || $wallpaper_in_config != ${wallpaper_directory}${chosen_image} ]]; then
  echo "\$wallpaper_in_config = ${wallpaper_directory}${chosen_image}" > ${wallpaper_hypr_config}
  
  if [[ ! $? ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "Couldn't write new wallpaper path in ${wallpaper_hypr_config}"
    exit 7
  fi
  
  swww img $chosen_image
  
  matugen image $chosen_image
  hyprctl reload
  
  wallust run $chosen_image
  python $kitty_python_script $kitty_colors_raw $kitty_colors_tweaked
  killall -SIGUSR1 kitty
  
  notify-send -t 3000 "Wallpaper changer" "Wallpaper changed"
else
  notify-send -t 3000 "Wallpaper changer" "No changes"
fi
  
