import curses
import subprocess

def main(stdscr):
    stdscr.clear()
    curses.curs_set(0)
    stdscr.keypad(True)
    curses.start_color()
    curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_BLUE)

    menu = [
        ("Build", [
            ("Build    - Build and deploy all", "./starter.sh build"), 
            ("Destroy  - Destroy all",          "./starter.sh destroy"),
            ("Log      - Show last build log",  "cat target/build.log")
        ]),
        ("Other", [("Help", "./starter.sh help"), ("Exit", None)])
    ]

    current_item = 0
    current_subitem = 0  # Start with the first command selected

    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, f"OCI Starter")
        stdscr.addstr(1, 0, f"-----------")
        y=2
        for i, (topic, commands) in enumerate(menu):
            stdscr.addstr(y, 0, topic)  # Topic headers are NOT selectable
            y += 1
            if commands:
                for j, (command, command_path) in enumerate(commands):
                    if i == current_item and j == current_subitem:
                        stdscr.attron(curses.color_pair(1))
                        selected_command = command_path
                    stdscr.addstr(y, 2, command)
                    stdscr.attroff(curses.color_pair(1))
                    y += 1

        # Display the selected command at the bottom
        stdscr.addstr(y + 1, 0, f"Command: {selected_command or 'None'}")

        key = stdscr.getch()

        if key == curses.KEY_UP:
            if current_item == 0 and current_subitem == 0: #prevent going up from first command
                continue
            if current_subitem > 0:
                current_subitem -= 1
            else:
                current_item -= 1
                if menu[current_item][1]:
                    current_subitem = len(menu[current_item][1]) - 1
                else: #if it is exit
                    current_subitem = 0
        elif key == curses.KEY_DOWN:
            if current_item == len(menu)-1 and current_subitem == 1: #prevent going down from exit
                continue
            if menu[current_item][1] and current_subitem < len(menu[current_item][1]) - 1:
                current_subitem += 1
            else:
                current_item += 1
                if menu[current_item][1]:
                    current_subitem = 0
                else: #if it is exit
                    current_subitem = 0

        elif key in (curses.KEY_ENTER, 10):
            selected_item = menu[current_item]
            if selected_command is None:
                break
            elif selected_item[1]:
                command_to_run = selected_item[1][current_subitem][1]
                curses.endwin()
                try:
                    subprocess.run(["bash", "-c", command_to_run], check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Error executing {command_to_run}: {e}")
                except FileNotFoundError:
                    print(f"Error: {command_to_run} not found")
                break

if __name__ == "__main__":
    curses.wrapper(main)

