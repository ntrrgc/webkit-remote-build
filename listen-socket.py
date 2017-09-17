#!/usr/bin/python3
import fcntl
import os
import socket
import sys

sys.stdout = os.fdopen(1, 'wb', 0)


def is_stdout_open():
    try:
        fcntl.fcntl(1, fcntl.F_GETFL)
        return True
    except OSError:
        return False


if __name__ == '__main__':
    try:
        s = socket.socket(socket.AF_UNIX)
        s.bind(sys.argv[1])
        s.listen(1000)

        while is_stdout_open():
            ss, address = s.accept()
            while True:
                block = ss.recv(2048)
                if len(block) == 0:
                    ss.close()
                    break

                sys.stdout.write(block)
    except KeyboardInterrupt:
        pass
