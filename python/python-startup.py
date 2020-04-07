import readline
import atexit
import os

histfile = os.path.join(os.environ['HOME'], '.cache/python/.python_history')

try:
    readline.read_history_file(histfile)
except IOError:
    pass

atexit.register(readline.write_history_file, histfile)
