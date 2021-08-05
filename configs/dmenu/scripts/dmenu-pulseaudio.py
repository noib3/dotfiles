import argparse
import re
import subprocess
from typing import List, Optional

__author__ = 'Riccardo Mazzarini (noib3)'
__email__ = 'riccardo.mazzarini@pm.me'

parser = argparse.ArgumentParser()
parser.add_argument(
    '-v',
    '--volume',
    help='Lower, raise or mute the volume of the default sink'
)


class Sink:

    def __init__(self, lines: List[str]):
        self.index = lines[0].split()[-1]
        self.is_default = '*' in lines[0]
        for line in lines:
            if 'device.description' in line:
                self.description = line.split('= ')[1][1:-1]
            elif 'volume: front-left' in line:
                self.volume = int(line.split(' / ')[1].strip('%'))
            elif 'muted' in line:
                self.is_muted = 'yes' in line

    def set_as_default(self):
        proc = subprocess.run(['pactl', 'set-default-sink', self.index])
        if proc.returncode == 0:
            self.is_default = True

    def lower_volume(self, step=5):
        proc = subprocess.run(['pactl', 'set-sink-volume', self.index,
                               '-{}%'.format(step)])
        if proc.returncode == 0:
            if self.volume > 0:
                self.volume -= step
            subprocess.run(['dunstify', 'Volume: {}%'.format(self.volume),
                            '--appname', self.description, '--replace', '1',
                            '--timeout', '1500'])

    def raise_volume(self, step=5):
        proc = subprocess.run(['pactl', 'set-sink-volume', self.index,
                               '+{}%'.format(step)])
        if proc.returncode == 0:
            self.volume += step
            subprocess.run(['dunstify', 'Volume: {}%'.format(self.volume),
                            '--appname', self.description, '--replace', '1',
                            '--timeout', '1500'])

    def toggle_mute(self):
        proc = subprocess.run(['pactl', 'set-sink-mute', self.index, 'toggle'])
        if proc.returncode == 0:
            self.is_muted = not self.is_muted
            volume = self.is_muted and 'Muted' or '{}%'.format(self.volume)
            subprocess.run(['dunstify', 'Volume: {}'.format(volume),
                            '--appname', self.description, '--replace', '1',
                            '--timeout', '1500'])

    def show_menu(self):
        preselect_index = 0
        while True:
            lower_volume = 'Lower volume'
            raise_volume = 'Raise volume'
            mute = self.is_muted and 'Unmute' or 'Mute'
            set_default = ''
            if not self.is_default:
                set_default = 'Set as default sink'

            option_entries = '\n'.join([
                lower_volume,
                raise_volume,
                mute,
                set_default,
            ])

            selection = subprocess.run(
                ['dmenu', '-p', '{description}{is_default}>'.format(
                    description=self.description,
                    is_default=self.is_default and ' (*)' or ''
                ), '-n', str(preselect_index)],
                capture_output=True,
                text=True,
                input=option_entries,
            ).stdout.rstrip()

            if not selection:
                break

            elif selection == lower_volume:
                preselect_index = 0
                self.lower_volume()

            elif selection == raise_volume:
                preselect_index = 1
                self.raise_volume()

            elif selection == mute:
                preselect_index = 2
                self.toggle_mute()

            elif selection == set_default:
                preselect_index = 3
                self.set_as_default()


class Input:

    def __init__(self):
        pass


def get_sinks() -> List[Sink]:
    sinks_dump = subprocess.run(
        ['pacmd', 'list-sinks'],
        capture_output=True,
        text=True,
    ).stdout.rstrip().split('\n')

    i = -1
    sinks = []
    for line in sinks_dump[1:]:
        # Match lines of the form
        #   '    index: 0'
        # or
        #   '  * index: 3'
        if re.match(r'^  ( |\*) index: [0-9]*$', line):
            sinks.append([])
            i += 1
        sinks[i].append(line)

    return [Sink(lines=lines) for lines in sinks]


def get_default_sink() -> Optional[Sink]:
    for sink in get_sinks():
        if sink.is_default:
            return sink


def show_menu():
    preselect_index = 0
    while True:
        sinks = get_sinks()
        sink_entries = [
            '{description}{is_default}'.format(
                description=s.description,
                is_default=s.is_default and ' (*)' or ''
            ) for s in sinks
        ]

        selection = subprocess.run(
            ['dmenu', '-p', 'Sinks>', '-n', str(preselect_index)],
            capture_output=True,
            text=True,
            input='\n'.join(sink_entries),
        ).stdout.rstrip()

        if not selection:
            break

        elif selection in sink_entries:
            for i, s in enumerate(sinks):
                if s.description in selection:
                    preselect_index = i
                    s.show_menu()
                    break


if __name__ == '__main__':
    args = parser.parse_args()
    if args.volume:
        default_sink = get_default_sink()
        if args.volume == 'lower':
            default_sink.lower_volume()
        elif args.volume == 'raise':
            default_sink.raise_volume()
        elif args.volume == 'toggle':
            default_sink.toggle_mute()
    else:
        show_menu()
