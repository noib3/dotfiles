import subprocess

import dmenu


def __shutdown():
    subprocess.run(['sudo', 'shutdown', '--poweroff', 'now'])


def __reboot():
    subprocess.run(['sudo', 'shutdown', '--reboot', 'now'])


def __suspend():
    subprocess.run(['systemctl', 'suspend'])


def show_menu():
    """Launches dmenu with the options to shutdown, reboot or suspend the
    machine."""

    TUX_ICON = ' '

    options = [
        shutdown := 'Shutdown',
        reboot := 'Reboot',
        suspend := 'Suspend',
    ]

    while True:
        selection = dmenu.show(prompt=TUX_ICON, items=options)

        if not selection:
            break

        elif selection == shutdown:
            __shutdown()

        elif selection == reboot:
            __reboot()

        elif selection == suspend:
            __suspend()


if __name__ == '__main__':
    show_menu()
