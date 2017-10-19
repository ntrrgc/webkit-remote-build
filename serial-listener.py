#!/usr/bin/python3
# Listen on the UNIX domain socket specified as parameter, one connection at
# a time. The data sent from each client is written to stdout.
#
# The program exits if an 'end' packet is received, identified by being a
# connection whose first 4 bytes transferred are 'end\n'.
#
import fcntl
import os
import socket
import sys
import select

sys.stdout = os.fdopen(1, 'wb', 0)


def recv_exact_bytes(socket, size):
    buf = b""
    while True:
        new_buf = socket.recv(size - len(buf))
        if len(new_buf) == 0:
            # Connection closed, no more data to receive
            return buf

        buf += new_buf
        if len(buf) == size:
            # Received all awaited data
            return buf


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
                    # stdout closed, exit
                    raise SystemExit(0)
                elif fd == s.fileno() and event_type == select.POLLIN:
                    # Connection received
                    ss, address = s.accept()

                    possible_end_block = recv_exact_bytes(ss, 4)
                    if possible_end_block == b"end\n":
                        # exit due to 'end' packet
                        raise SystemExit(0)
                    else:
                        # Not an 'end' packet, but regular data
                        sys.stdout.write(possible_end_block)

                    # Keep receiving and forwarding to stdout until the
                    # connection is closed.
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
