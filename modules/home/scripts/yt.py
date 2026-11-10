import os
import socket
import sys

import dns.resolver
import yt_dlp

# A resolver that queries Cloudflare's DNS directly, bypassing /etc/hosts.
resolver = dns.resolver.Resolver(configure=False)
resolver.nameservers = ["1.1.1.1"]

system_getaddrinfo = socket.getaddrinfo


def getaddrinfo(host, *args, **kwargs):
    if isinstance(host, str) and (
        host == "youtube.com" or host.endswith(".youtube.com")
    ):
        host = resolver.resolve(host, "A")[0].address
    return system_getaddrinfo(host, *args, **kwargs)


socket.getaddrinfo = getaddrinfo

yt_dlp.main(
    [
        "--merge-output-format",
        "mkv",
        "--paths",
        os.path.expanduser("~/Downloads"),
        "--output",
        "%(title)s [%(id)s].%(ext)s",
        *sys.argv[1:],
    ]
)
