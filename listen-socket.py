#!/usr/bin/python3
# Listen on the UNIX domain socket specified as parameter, one connection at
# a time. The data sent from each client is written to stdout.
#
# The program exits when stdout is closed.
#
# Closing stdout while a client is sending data is an error and will raise a
# BrokenPipeError.
#
import fcntl
import os
import socket
import sys
import select

sys.stdout = os.fdopen(1, 'wb', 0)


if __name__ == '__main__':
    try:
        s = socket.socket(socket.AF_UNIX)
        s.bind(sys.argv[1])
        s.listen(1000)

        poll = select.poll()
        poll.register(s.fileno())
        poll.register(sys.stdout.fileno(), select.POLLERR)

        while True:
            for (fd, event_type) in poll.poll():
                if fd == sys.stdout.fileno() and event_type == select.POLLERR:
                    # stdout closed
                    raise SystemExit(0)
                elif fd == s.fileno() and event_type == select.POLLIN:
                    # Connection received
                    ss, address = s.accept()
                    while True:
                        block = ss.recv(2048)
                        if len(block) == 0:
                            ss.close()
                            break

                        sys.stdout.write(block)
                else:
                    raise AssertionError(f"Unhandled event: fd={fd} "
                                         "event_type={event_type}",
                                         file=sys.stderr)
    except KeyboardInterrupt:
        pass
