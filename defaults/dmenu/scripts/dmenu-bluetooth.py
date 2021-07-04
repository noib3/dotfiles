"""dmenu-bluetooth

Usage:
    dmenu-bluetooth [--status]
"""

import argparse
import os
import subprocess
import sys
from time import sleep
from typing import List

__author__ = 'Riccardo Mazzarini (noib3)'
__email__ = 'riccardo.mazzarini@pm.me'

parser = argparse.ArgumentParser()
parser.add_argument(
    '-s',
    '--status',
    action='store_true',
    help='show a short status message (useful for status bars like polybar)'
)

POWER_ON_FG = os.getenv('POWER_ON_FG', '')
POWER_OFF_FG = os.getenv('POWER_OFF_FG', '')
CONNECTED_FG = os.getenv('CONNECTED_FG', '')


# TODO
# 1. What's the difference between 'discovering', 'pairing' and 'scanning' in
# the main menu?
# 2. remove as much overhead as possible
# 3. refactor
# 4. send notifications
# 5. use emojis

class Device:
    FORMAT_MENU = """\
{connected}
{paired}
{trusted}
"""

    def __init__(self, line: str):
        fields = line.split(' ')
        self.address = fields[1]
        self.name = ' '.join(fields[2:])

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
        proc = subprocess.run(['bluetoothctl', toggle, self.address])
        return toggle, proc.returncode

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
        preselect_index = 0
        while True:
            connected = self.__is_connected() and 'Disconnect' or 'Connect'
            paired = self.__is_paired() and 'Unpair' or 'Pair'
            trusted = self.__is_trusted() and 'Untrust' or 'Trust'

            options = self.FORMAT_MENU.format(
                connected=connected,
                paired=paired,
                trusted=trusted,
            )

            selection = subprocess.run(
                ['dmenu', '-p', '{}>'.format(self.name),
                 '-n', str(preselect_index)],
                capture_output=True,
                text=True,
                input=options,
            ).stdout.rstrip()

            if not selection:
                break

            elif selection == connected:
                preselect_index = 0
                toggle, ret_code = self.__toggle_connected()
                if toggle == 'connect' and ret_code == 0:
                    sys.exit()

            elif selection == paired:
                preselect_index = 1
                self.__toggle_paired()

            elif selection == trusted:
                preselect_index = 2
                self.__toggle_trusted()


class Bluetooth:
    ICON_POWER_ON = ''
    ICON_POWER_OFF = ''
    ICON_CONNECTED = ''
    STATUS_FORMAT = '{icon}{info}'

    MAIN_MENU_FORMAT = """\
{list_devices}
{discovering}
{pairing}
{scanning}
{power}
"""

    def __get_status(self) -> str:
        return subprocess.run(
            ['bluetoothctl', 'show'],
            capture_output=True,
            text=True,
        ).stdout.rstrip()

    def __get_paired_devices(self) -> List[Device]:
        devices = subprocess.run(
            ['bluetoothctl', 'paired-devices'],
            capture_output=True,
            text=True,
        ).stdout.rstrip()
        return [Device(line) for line in devices.split('\n') if line]

    def __get_connected_devices(self) -> List[Device]:
        return [d for d in self.__get_paired_devices() if d.is_connected()]

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
        proc = subprocess.run(['bluetoothctl', 'power', toggle])
        return toggle, proc.returncode

    def __toggle_discovering(self):
        toggle = self.__is_discoverable() and 'off' or 'on'
        subprocess.run(['bluetoothctl', 'discoverable', toggle])

    def __toggle_pairing(self):
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

    def __show_devices_menu(self):
        preselect_index = 0
        while True:
            paired_devices = self.__get_paired_devices()
            device_names = [
                '{}{}'.format(d.name, d.is_connected() and ' (c)' or '')
                for d in paired_devices
            ]

            selection = subprocess.run(
                ['dmenu', '-p', 'Devices>', '-n', str(preselect_index)],
                capture_output=True,
                text=True,
                input='\n'.join(device_names),
            ).stdout.rstrip()

            if not selection:
                break

            elif selection in device_names:
                for i, d in enumerate(paired_devices):
                    if d.name in selection:
                        preselect_index = i
                        d.show_menu()
                        break

    def print_status(self):
        """Prints a short string with the current Bluetooth status."""
        def polybar_format(fg: str, msg: str) -> str:
            fmt = '%{{F{fg}}}{msg}%{{F-}}'
            return fmt.format(fg=fg, msg=msg)

        info = ''
        if self.__is_on():
            connected_devices = self.__get_connected_devices()
            if len(connected_devices) == 0:
                icon = polybar_format(
                    fg=POWER_ON_FG,
                    msg=self.ICON_POWER_ON
                )
            else:
                icon = polybar_format(
                    fg=CONNECTED_FG,
                    msg=self.ICON_CONNECTED
                )
                info = ' {}'.format(
                    len(connected_devices) == 1
                    and connected_devices[0].name
                    or len(connected_devices)
                )
        else:
            icon = polybar_format(
                fg=POWER_OFF_FG,
                msg=self.ICON_POWER_OFF
            )

        print(self.STATUS_FORMAT.format(icon=icon, info=info))

    def show_main_menu(self):
        """Launches dmenu with the current Bluetooth status and options to
        connect."""
        preselect_index = 0
        while True:
            if self.__is_on():
                list_devices = 'List devices'
                discovering = '{} discovering'.format(
                    self.__is_discoverable() and 'Stop' or 'Start')
                pairing = '{} pairing'.format(
                    self.__is_pairable() and 'Stop' or 'Start')
                scanning = '{} scanning'.format(
                    self.__is_scanning() and 'Stop' or 'Start')
                power = 'Turn off'
            else:
                list_devices = ''
                discovering = ''
                pairing = ''
                scanning = ''
                power = 'Turn on'

            options = '\n'.join([line for line in self.MAIN_MENU_FORMAT.format(
                list_devices=list_devices,
                discovering=discovering,
                pairing=pairing,
                scanning=scanning,
                power=power,
            ).split('\n') if line])

            selection = subprocess.run(
                ['dmenu', '-p', 'Bluetooth>', '-n', str(preselect_index)],
                capture_output=True,
                text=True,
                input=options,
            ).stdout.rstrip()

            if not selection:
                sys.exit()

            elif selection == list_devices:
                preselect_index = 0
                self.__show_devices_menu()

            elif selection == discovering:
                preselect_index = 1
                self.__toggle_discovering()

            elif selection == pairing:
                preselect_index = 2
                self.__toggle_pairing()

            elif selection == scanning:
                preselect_index = 3
                self.__toggle_scanning()

            elif selection == power:
                preselect_index = 0
                toggle, ret_code = self.__toggle_power()
                if toggle == 'off' and ret_code == 0:
                    sys.exit()


if __name__ == '__main__':
    args = parser.parse_args()
    bluetooth = Bluetooth()
    if args.status:
        bluetooth.print_status()
    else:
        bluetooth.show_main_menu()
