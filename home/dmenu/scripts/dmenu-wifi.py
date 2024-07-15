import subprocess
import sys
from typing import List

__author__ = 'Riccardo Mazzarini (noib3)'
__email__ = 'riccardo.mazzarini@pm.me'


class Network:

    def __init__(self, line: str):
        fields = line.split(':')
        self.ssid = fields[0]
        self.bars = fields[1]
        self.signal = fields[2]
        self.is_password_protected = fields[3] != ''

    def __is_connected(self) -> bool:
        active_connections_names = subprocess.run(
            [
                'nmcli', '--color', 'no', '--terse', '--fields', 'NAME',
                'connection', 'show', '--active'
            ],
            capture_output=True,
            text=True,
        ).stdout.rstrip()

        # NOTE: this assumes a connection's name is equal to the corresponding
        # network's SSID.
        return self.ssid in active_connections_names.split('\n')

    def __is_known(self) -> bool:
        known_connections_names = subprocess.run(
            [
                'nmcli', '--color', 'no', '--terse', '--fields', 'NAME',
                'connection', 'show'
            ],
            capture_output=True,
            text=True,
        ).stdout.rstrip()

        # NOTE: this assumes a connection's name is equal to the corresponding
        # network's SSID.
        return self.ssid in known_connections_names.split('\n')

    def __is_autoconnected(self) -> bool:
        autoconnected = False
        known_connections = subprocess.run(
            [
                'nmcli', '--color', 'no', '--terse', '--fields',
                'NAME,AUTOCONNECT', 'connection', 'show'
            ],
            capture_output=True,
            text=True,
        ).stdout.rstrip()

        for connection in known_connections.split('\n'):
            name, autoconnect_flag = connection.split(':')
            # NOTE: this assumes a connection's name is equal to the
            # corresponding network's SSID.
            if self.ssid == name:
                autoconnected = autoconnect_flag == 'yes'
        return autoconnected

    def __toggle_connected(self):
        if self.__is_connected():
            # NOTE: this assumes a connection's name is equal to the
            # corresponding network's SSID.
            toggle = 'disconnect'
            proc = subprocess.run(['nmcli', 'connection', 'down', self.ssid])
        else:
            toggle = 'connect'
            if self.__is_known():
                # NOTE: this assumes a connection's name is equal to the
                # corresponding network's SSID.
                proc = subprocess.run(['nmcli', 'connection', 'up', self.ssid])
            else:
                if self.is_password_protected:
                    while True:
                        password = subprocess.run(
                            ['dmenu', '-p', 'Password>', '-P'],
                            capture_output=True,
                            text=True,
                        ).stdout.rstrip()
                        if not password:
                            sys.exit()
                        # NOTE: this sets a new connection's name equal to the
                        # corresponding network's SSID.
                        proc = subprocess.run([
                            'sudo', 'nmcli', 'device', 'wifi', 'connect',
                            self.ssid, 'password', password, 'name', self.ssid
                        ])
                        if proc.returncode == 0:
                            break
                        else:
                            subprocess.run([
                                'dunstify', 'Incorrect password', '--appname',
                                self.ssid, '--replace', '1', '--timeout',
                                '2000'
                            ])
                else:
                    # NOTE: this sets a new connection's name equal to the
                    # corresponding network's SSID.
                    proc = subprocess.run([
                        'sudo', 'nmcli', 'device', 'wifi', 'connect',
                        self.ssid, 'name', self.ssid
                    ])
        return toggle, proc.returncode

    def __forget(self):
        # NOTE: this assumes a connection's name is equal to the corresponding
        # network's SSID.
        subprocess.run(
            ['sudo', 'nmcli', 'connection', 'delete', 'id', self.ssid])

    def __toggle_autoconnect(self):
        toggle = self.__is_autoconnected() and 'no' or 'yes'
        # NOTE: this assumes a connection's name is equal to the corresponding
        # network's SSID.
        subprocess.run([
            'sudo', 'nmcli', 'connection', 'modify', 'id', self.ssid,
            'connection.autoconnect', toggle
        ])

    def is_connected(self) -> bool:
        return self.__is_connected()

    def show_menu(self):
        """A submenu for a specific network that allows connecting."""
        preselect_index = 0
        while True:
            connected = self.__is_connected() and 'Disconnect' or 'Connect'
            if self.__is_known():
                forget = 'Forget'
                autoconnect = '{} autoconnect'.format(
                    self.__is_autoconnected() and 'Disable' or 'Enable')
            else:
                forget = ''
                autoconnect = ''

            entries = '\n'.join([connected, forget, autoconnect])

            selection = subprocess.run(
                [
                    'dmenu', '-p', '{} {} ({}%)>'.format(
                        self.bars, self.ssid, self.signal), '-n',
                    str(preselect_index)
                ],
                capture_output=True,
                text=True,
                input=entries,
            ).stdout.rstrip()

            if not selection:
                break

            elif selection == connected:
                preselect_index = 0
                toggle, ret_code = self.__toggle_connected()
                if toggle == 'connect' and ret_code == 0:
                    sys.exit()

            elif selection == forget:
                preselect_index = 1
                self.__forget()

            elif selection == autoconnect:
                preselect_index = 2
                self.__toggle_autoconnect()


class Wifi:

    def __get_status(self) -> str:
        return subprocess.run(
            ['nmcli', '--color', 'no', 'radio', 'wifi'],
            capture_output=True,
            text=True,
        ).stdout.rstrip()

    def __get_networks(self, rescan: bool) -> List[Network]:
        networks = subprocess.run(
            [
                'nmcli', '--color', 'no', '--terse', '--fields',
                'SSID,BARS,SIGNAL,SECURITY', 'device', 'wifi', 'list',
                '--rescan', rescan and 'yes' or 'no'
            ],
            capture_output=True,
            text=True,
        ).stdout.rstrip()
        return [Network(line) for line in networks.split('\n') if line]

    def __is_on(self) -> bool:
        return self.__get_status() == 'enabled'

    def __toggle_power(self):
        toggle = self.__is_on() and 'off' or 'on'
        proc = subprocess.run(['nmcli', 'radio', 'wifi', toggle])
        return toggle, proc.returncode

    def __show_networks_menu(self):
        preselect_index = 0
        rescan = True
        while True:
            networks = self.__get_networks(rescan)
            network_infos = [
                '{}{}{} {}'.format(n.ssid,
                                   n.is_connected() and ' (c)' or '',
                                   n.is_password_protected and ' []' or '',
                                   n.bars) for n in networks
            ]

            selection = subprocess.run(
                ['dmenu', '-p', 'Networks>', '-n',
                 str(preselect_index)],
                capture_output=True,
                text=True,
                input='\n'.join(network_infos),
            ).stdout.rstrip()

            if not selection:
                break

            elif selection in network_infos:
                for i, n in enumerate(networks):
                    if n.ssid in selection:
                        preselect_index = i
                        n.show_menu()
                        break

            rescan = False

    def show_main_menu(self):
        """Launches dmenu with the current WiFi status and options to
        connect."""
        preselect_index = 0
        while True:
            if self.__is_on():
                list_networks = 'List networks'
                power = 'Turn off'
            else:
                list_networks = ''
                power = 'Turn on'

            entries = '\n'.join([list_networks, power])

            selection = subprocess.run(
                ['dmenu', '-p', 'Wifi>', '-n',
                 str(preselect_index)],
                capture_output=True,
                text=True,
                input=entries,
            ).stdout.rstrip()

            if not selection:
                break

            elif selection == list_networks:
                preselect_index = 0
                self.__show_networks_menu()

            elif selection == power:
                preselect_index = 0
                toggle, ret_code = self.__toggle_power()
                if toggle == 'off' and ret_code == 0:
                    sys.exit()


if __name__ == '__main__':
    wifi = Wifi()
    wifi.show_main_menu()
