import subprocess
import sys

POWER_ICON = '⏻ '
FORMAT_MENU = """\
{shutdown}
{reboot}
{suspend}
{lock}
"""


def __shutdown():
    subprocess.run(['sudo', 'shutdown', '--poweroff', 'now'])


def __reboot():
    subprocess.run(['sudo', 'shutdown', '--reboot', 'now'])


def __suspend():
    subprocess.run(['systemctl', 'suspend'])


def __lock():
    subprocess.run(['i3lock'])


def show_menu():
    """Launches dmenu with the options to shutdown, reboot, suspend or lock the
    machine."""
    shutdown = 'Shutdown'
    reboot = 'Reboot'
    suspend = 'Suspend'
    lock = 'Lock'

    options = FORMAT_MENU.format(
        shutdown=shutdown,
        reboot=reboot,
        suspend=suspend,
        lock=lock,
    )

    selection = subprocess.run(
        ['dmenu', '-p', POWER_ICON],
        capture_output=True,
        text=True,
        input=options,
    ).stdout.rstrip()

    if not selection:
        sys.exit()

    elif selection == shutdown:
        __shutdown()

    elif selection == reboot:
        __reboot()

    elif selection == suspend:
        __suspend()

    elif selection == lock:
        __lock()


if __name__ == '__main__':
    show_menu()
