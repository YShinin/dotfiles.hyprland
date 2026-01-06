import math
import os.path
import sys

# CHECKING HOW MANY ARGUMENTS HAS BEEN PASSED
if len(sys.argv) != 3:
    print("Usage: [path/to/generated/file] [path/to/output/config/file]")
    sys.exit()

# CHECKING WHETHER PATH IS VALID
if not os.path.isfile(sys.argv[1]):
    print(f"{sys.argv[1]} doesn't look like a file or just doesn't exist")
    sys.exit()

target_distance = 70
change_per_step = 0.3

# DICTIONARY OF REFERENCE COLORS
REF_COLORS = {
    # Normal colors (более спокойные)
    "color1": "#F38BA8",  # Red (Red)
    "color2": "#A6E3A1",  # Green (Green)
    "color3": "#F9E2AF",  # Yellow (Yellow)
    "color4": "#89B4FA",  # Blue (Blue)
    "color5": "#F5C2E7",  # Magenta (Pink)
    "color6": "#94E2D5",  # Cyan (Teal)
    # Bright colors (чуть насыщеннее, можно оставить те же или сделать ярче)
    "color9": "#F38BA8",  # Red
    "color10": "#A6E3A1",  # Green
    "color11": "#F9E2AF",  # Yellow
    "color12": "#89B4FA",  # Blue
    "color13": "#F5C2E7",  # Magenta
    "color14": "#94E2D5",  # Cyan
}


def parse_config_file() -> dict[str, str]:
    # OPENING CONFIG FILE
    with open(sys.argv[1], "r") as config_file:
        resulting_dictionary: dict[str, str] = {}
        # READING LINE BY LINE IN FOR LOOP
        for line in config_file:
            # REMOVING NEWLINES AND EXCESS WHITESPACES
            line = line.rstrip("\n")
            line = line.split()

            # CHECKING IF OUR LINE IS COMMENT OR EMPTY OR WHERE SUPPOSED TO BE HEX THER IS NO HASH SYMBOL
            if len(line) != 2 or line[0] == "#" or line[1][0] != "#":
                continue

            # ADDING RECORD TO THE DICTIONARY
            resulting_dictionary[line[0]] = line[1]
    return resulting_dictionary


def write_config_file(parsed_dict: dict[str, str], tweaked_dict: dict[str, str]):
    with open(sys.argv[2], "w") as new_config:
        new_config.write(
            f"# Created by {sys.argv[0]}\n# Target distance between colors (0-256): {target_distance}\t Color change per step (0-1) - {change_per_step}\n\n"
        )

        new_config.write("# Unchanged variables\n")
        for color, value in parsed_dict.items():
            if tweaked_dict.get(color):
                continue
            else:
                new_config.write(f"{color} {value}\n")

        new_config.write("\n# Changed variables\n")
        for color, value in tweaked_dict.items():
            new_config.write(f"{color} {value}\n")
            new_config.write(f"# was {parsed_dict.get(color)}\n")


def hex_to_rgb(hex_str: str):
    hex_str = hex_str.lstrip("#")

    # RETURNING TUPLE OF INTEGERS
    return (int(hex_str[:2], 16), int(hex_str[2:4], 16), int(hex_str[4:], 16))


def rgb_to_hex(rgb: tuple[int, int, int]):
    # IDK HOW IT WORKS BUT IT ADDS NEEDED ZEROES
    return "#{:02x}{:02x}{:02x}".format(int(rgb[0]), int(rgb[1]), int(rgb[2]))


def calculating_color_distance(
    f_color: tuple[int, int, int], s_color: tuple[int, int, int]
) -> float:
    # ЭВКЛИДОВА МЕТРИКА
    return math.sqrt(
        (f_color[0] - s_color[0]) ** 2
        + (f_color[1] - s_color[1]) ** 2
        + (f_color[2] - s_color[2]) ** 2
    )


def mix_colors(main_color: tuple[int, int, int], ref_color: tuple[int, int, int]):
    # MIXING COLOR ACCORDIG TO LINEAR INTERPOLATION
    return (
        int(main_color[0] + (ref_color[0] - main_color[0]) * change_per_step),
        int(main_color[1] + (ref_color[1] - main_color[1]) * change_per_step),
        int(main_color[2] + (ref_color[2] - main_color[2]) * change_per_step),
    )


def main():
    # PARSING OUR FILE
    config_dictionary = parse_config_file()

    correct_colors_dictionary = {}

    # LOOP FOR EVERY COLOR WE NEED TO CORRECT
    for active_color, acitve_color_hex in REF_COLORS.items():
        config_color_hex = config_dictionary.get(active_color)

        # PRINT ERROR IF THERE IS NO ACTIVE_COLOR IN CONFIG
        if not config_color_hex:
            print(f"Error, couldn't find {active_color} in config file, skipping.. ")
            continue

        active_color_rgb = hex_to_rgb(acitve_color_hex)
        config_color_rgb = hex_to_rgb(config_color_hex)

        # CALCULATING DISTANCE BETWEEN COLORS
        dist = calculating_color_distance(config_color_rgb, active_color_rgb)

        while dist > target_distance:
            config_color_rgb = mix_colors(config_color_rgb, active_color_rgb)
            # print(f"changin color for {active_color}")
            dist = calculating_color_distance(config_color_rgb, active_color_rgb)

        # print(
        #     f"Color name - {active_color}\n\tBefore - {config_color_hex}\n\tAfter - {rgb_to_hex(config_color_rgb)}\n"
        # )
        correct_colors_dictionary[active_color] = rgb_to_hex(config_color_rgb)

    write_config_file(config_dictionary, correct_colors_dictionary)


if __name__ == "__main__":
    main()
