"""dmenu-bluetooth

Usage:
    dmenu-bluetooth [--status]
"""

# Python rewrite of https://github.com/nickclyde/rofi-bluetooth for dmenu.

import os
import subprocess
import sys
from time import sleep
from typing import List

from docopt import docopt

__author__ = 'Riccardo Mazzarini (noib3)'
__email__ = 'riccardo.mazzarini@pm.me'
__credits__ = ['Nick Clyde']

# TODO
# 1. pass any cli argument different from --status directly to dmenu


class Device:
    FORMAT_MENU = """\
{connected}
{paired}
{trusted}
{divider}
{back}
{exit}
"""

    def __init__(self, line: str):
        self.address = line.split(' ')[1]
        self.name = ' '.join(line.split(' ')[2:])

    def __get_info(self) -> str:
        return subprocess.run(
            ['bluetoothctl', 'info', self.address],
            capture_output=True,
            text=True,
        ).stdout

    def __is_connected(self) -> bool:
        return 'Connected: yes' in self.__get_info()

    def __is_paired(self) -> bool:
        return 'Paired: yes' in self.__get_info()

    def __is_trusted(self) -> bool:
        return 'Trusted: yes' in self.__get_info()

    def __toggle_connected(self):
        toggle = self.__is_connected() and 'disconnect' or 'connect'
        subprocess.run(['bluetoothctl', toggle, self.address])

    def __toggle_paired(self):
        toggle = self.__is_paired() and 'remove' or 'pair'
        subprocess.run(['bluetoothctl', toggle, self.address])

    def __toggle_trusted(self):
        toggle = self.__is_trusted() and 'untrust' or 'trust'
        subprocess.run(['bluetoothctl', toggle, self.address])

    def is_connected(self):
        return self.__is_connected()

    def show_menu(self):
        """A submenu for a specific device that allows connecting, pairing, and
        trusting."""
        while True:
            connected = 'Connected: {}'.format(
                self.__is_connected() and 'yes' or 'no')
            paired = 'Paired: {}'.format(
                self.__is_paired() and 'yes' or 'no')
            trusted = 'Trusted: {}'.format(
                self.__is_trusted() and 'yes' or 'no')

            options = self.FORMAT_MENU.format(
                connected=connected,
                paired=paired,
                trusted=trusted,
                divider='-----------',
                back='Back',
                exit='Exit',
            )

            selection = subprocess.run(
                ['dmenu', '-p', '{}> '.format(self.name), '-l', '6'],
                capture_output=True,
                text=True,
                input=options,
            ).stdout.rstrip()

            if selection == connected:
                self.__toggle_connected()

            elif selection == paired:
                self.__toggle_paired()

            elif selection == trusted:
                self.__toggle_trusted()

            elif selection == 'Back':
                break

            elif not selection or selection == 'Exit':
                sys.exit()


class Bluetooth:
    ICON_POWER_ON = ''
    ICON_POWER_OFF = ''
    ICON_DEVICE_CONNECTED = ''

    FORMAT_STATUS = '{icon}{info}'
    FORMAT_MENU = """\
{devices}
{divider}
{power}
{discoverable}
{pairable}
{scanning}
{exit}
"""

    def __get_status(self) -> str:
        return subprocess.run(
            ['bluetoothctl', 'show'],
            capture_output=True,
            text=True,
        ).stdout

    def __get_paired_devices(self) -> List[Device]:
        proc = subprocess.run(
            ['bluetoothctl', 'paired-devices'],
            capture_output=True,
            text=True,
        )
        return [Device(line) for line in proc.stdout.split('\n') if line]

    def __is_on(self) -> bool:
        return 'Powered: yes' in self.__get_status()

    def __is_discoverable(self) -> bool:
        return 'Discoverable: yes' in self.__get_status()

    def __is_pairable(self) -> bool:
        return 'Pairable: yes' in self.__get_status()

    def __is_scanning(self) -> bool:
        return 'Discovering: yes' in self.__get_status()

    def __toggle_power(self):
        toggle = self.__is_on() and 'off' or 'on'
        subprocess.run(['bluetoothctl', 'power', toggle])

    def __toggle_discoverable(self):
        toggle = self.__is_discoverable() and 'off' or 'on'
        subprocess.run(['bluetoothctl', 'discoverable', toggle])

    def __toggle_pairable(self):
        toggle = self.__is_pairable() and 'off' or 'on'
        subprocess.run(['bluetoothctl', 'pairable', toggle])

    def __toggle_scanning(self):
        if self.__is_scanning():
            scan_pid = int(subprocess.run(
                ['pgrep', '-f', 'bluetoothctl scan on'],
                capture_output=True,
                text=True,
            ).stdout.rstrip())
            os.kill(scan_pid, 9)
            subprocess.run(['bluetoothctl', 'scan', 'off'])
        else:
            subprocess.Popen(['bluetoothctl', 'scan', 'on'])
            sleep(3)

    def print_status(self):
        """Prints a short string with the current Bluetooth status."""
        if self.__is_on():
            paired_devices = self.__get_paired_devices()
            connected_devices = [d for d in paired_devices if d.is_connected()]

            icon = (
                len(connected_devices) != 0
                and self.ICON_DEVICE_CONNECTED
                or self.ICON_POWER_ON
            )
            info = ' ' + (
                len(connected_devices) == 1
                and connected_devices[0].name
                or len(connected_devices)
            )
        else:
            icon = self.ICON_POWER_OFF
            info = ''

        print(self.FORMAT_STATUS.format(icon=icon, info=info))

    def show_menu(self):
        """Launches dmenu with the current Bluetooth status and options to
        connect."""
        while True:
            if self.__is_on():
                paired_devices = self.__get_paired_devices()
                device_names = [d.name for d in paired_devices]
                divider = '-----------'
                power = 'Power: on'
                discoverable = 'Discoverable: {}'.format(
                    self.__is_discoverable() and 'yes' or 'no')
                pairable = 'Pairable: {}'.format(
                    self.__is_pairable() and 'yes' or 'no')
                scanning = 'Scanning: {}'.format(
                    self.__is_scanning() and 'yes' or 'no')
            else:
                device_names = []
                divider = ''
                power = 'Power: off'
                discoverable = ''
                pairable = ''
                scanning = ''

            options = '\n'.join([line for line in self.FORMAT_MENU.format(
                devices='\n'.join(device_names),
                divider=divider,
                power=power,
                discoverable=discoverable,
                pairable=pairable,
                scanning=scanning,
                exit='Exit',
            ).split('\n') if line])

            selection = subprocess.run(
                ['dmenu', '-p', 'Bluetooth> ', '-l', '10'],
                capture_output=True,
                text=True,
                input=options,
            ).stdout.rstrip()

            if selection == power:
                self.__toggle_power()

            elif selection == discoverable:
                self.__toggle_discoverable()

            elif selection == pairable:
                self.__toggle_pairable()

            elif selection == scanning:
                self.__toggle_scanning()

            elif selection in device_names:
                for d in paired_devices:
                    if selection == d.name:
                        d.show_menu()
                        break

            elif not selection or selection == 'Exit':
                sys.exit()


if __name__ == '__main__':
    args = docopt(__doc__, version='dmenu-bluetooth 0.0.1')
    bluetooth = Bluetooth()
    if args['--status']:
        bluetooth.print_status()
    else:
        bluetooth.show_menu()
