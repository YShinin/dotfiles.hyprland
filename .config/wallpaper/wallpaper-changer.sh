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
default_rasi_file="$HOME/.config/rofi/wallpaper-changer.rasi"

wallpaper_directory=$default_wd
cache_directory=$default_cd
wallpaper_hypr_config=$default_hc
kitty_python_script=$default_kps
kitty_colors_raw=$default_kitty_colors_raw
kitty_colors_tweaked=$default_kitty_colors_tweaked
rasi_file=$default_rasi_file

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
    -krc | --kitty-raw-colors)
      shift
      kitty_colors_raw="$1"
      ;;
    -ktc | --kitty-tweaked-colors)
      shift
      kitty_colors_tweaked="$1"
      ;;
    -rf | --rasi-file)
      shift
      rasi_file="$1"
      ;;
    -h | --help)
      echo "Usage: $(basename "$0") [args]
      -h  | --help    Show this menu
      
      -wd | --wallpaper-directory    Pass there your wallpaper folder 
          (default = ${default_wd})
          
      -cd | --cache-directory    Pass there your path to cache directory used for keeping image previews
          (default = ${default_cd})
          
      -rf | --rasi-file    Pass there path to rasi file for rofi
          (default = ${default_rasi_file})
          
      -hc | --hyprland-config    Pass there your path to config file where current wallpaper will be stored
        [NOTE file will be fully cleared after wallpaper change]
          (default = ${default_hc})
          
      -krc | --kitty-raw-colors    Pass there path to file with wallust colors generated with for kitty
          (default = ${default_kitty_colors_raw})
          
      -ktc | --kitty-tweaked-colors    Pass there path to file that will be imported to kitty (file must be separate from kitty-raw-colros)
          (default = ${default_kitty_colors_tweaked})"
      exit
      ;;
    *)
      notify-send -t 3000 "ERROR: Wallpaper changer" "Unexpected argument: ${1}. Use -h or --help for more information." 
      exit 1
      ;;
  esac
  shift
done

if [[ ! (-d $wallpaper_directory) ]]; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "${wallpaper_directory} doesn't exist" 
  exit 2
fi

if [[ ! -f $kitty_colors_raw ]]; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "${kitty_colors_raw} doesn't exist" 
  exit 3
fi

if [[ ! -f $kitty_colors_tweaked ]]; then
  notify-send -t 3000 "ERROR: Wallpaper changer" "${kitty_colors_tweaked} doesn't exist" 
  exit 3
fi

shopt -s nullglob
shopt -s nocaseglob

if [[ -e "$cache_directory" ]]; then
  if [[ ! ( -d "$cache_directory" ) ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "$cache_directory exists and it is not a directory"
    exit 2
  fi
else
  mkdir -p "$cache_directory"
fi

cd "$wallpaper_directory" || { notify-send "ERROR: Wallpaper changer" "cd ${wallpaper_directory} failed"; exit 1; }

chosen_image=$(
  for image_file in *.{png,jpg,jpeg}; do

    [[ -e "$image_file" ]] || continue

    image_without_extention="${image_file%.*}"
    notify-send "image file is ${image_file}" "image_without_extention ${image_without_extention}"
    
    target_cache_file="${cache_directory%/}/${image_file}"
    
    if [[ ! -f $target_cache_file ]]; then
      magick "${image_file}" -resize "300x300^" -gravity center -extent 300x300 "${target_cache_file}"
    fi
    echo -en "${image_without_extention}\0icon\x1f${target_cache_file}\n"
done | rofi -show-icons -dmenu -config ${rasi_file})

[[ ! -z $chosen_image ]] || exit 0

if [[ ! -f $wallpaper_hypr_config ]]; then
  touch $wallpaper_hypr_config

  if [[ ! $? ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "Coudn't create config file in {$wallpaper_hypr_config}, verify if directory is persent"
    exit 2
  fi
fi

found_file=$(find . -maxdepth 1 -name "${chosen_image}.*" -print -quit)

chosen_image=$(basename "$found_file")

if [[ -z "$chosen_image" ]]; then
    notify-send "ERROR: Wallpaper changer" "Could not find image file for selection"
    exit 1
fi

chosen_image="${wallpaper_directory%/}/${chosen_image}"

wallpaper_in_config=$(grep "^\$wallpaper_in_config" "$wallpaper_hypr_config" | sed "s/.*= //" | sed 's/#.*//')

if [[ -z $wallpaper_in_config || $wallpaper_in_config != ${chosen_image} ]]; then
  echo "\$wallpaper_in_config = ${chosen_image}" > ${wallpaper_hypr_config}
  
  if [[ ! $? ]]; then
    notify-send -t 3000 "ERROR: Wallpaper changer" "Couldn't write new wallpaper path in ${wallpaper_hypr_config}"
    exit 3
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
  
