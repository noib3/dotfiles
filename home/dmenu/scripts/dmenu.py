#!/usr/bin/env python3

import subprocess
from typing import List, Optional


def show(
    prompt: Optional[str] = None,
    items: List[str] = [],
    obfuscate: bool = False,
    preselect_index: Optional[int] = None,
) -> str:

    dmenu_cmd = ['dmenu']

    # Dmenu doesn't actually have an help command. 'dmenu --help' returns an
    # error so we capture stderr instead of stdout.
    help = subprocess.run(
        ['dmenu', '--help'],
        capture_output=True,
        text=True,
    ).stderr.rstrip()

    if prompt:
        dmenu_cmd.extend(['-p', prompt])

    if obfuscate:
        has_password_patch = 'P' in help
        if has_password_patch:
            dmenu_cmd.append('-P')

    if preselect_index:
        has_index_patch = '[-n number]' in help
        if has_index_patch:
            dmenu_cmd.extend(['-n', str(preselect_index)])

    return subprocess.run(
        dmenu_cmd,
        capture_output=True,
        text=True,
        input='\n'.join(items)
    ).stdout.rstrip()
