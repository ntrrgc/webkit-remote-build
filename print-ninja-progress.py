#!/usr/bin/python3
import sys
import re
from tqdm import tqdm

if __name__ == "__main__":
    pbar = None
    done_before = 0

    re_progress = re.compile(r"^\[(\d+)/(\d+)\] ")

    try:
        for line in sys.stdin:
            match = re_progress.match(line)
            if match:
                done = int(match.groups()[0])
                total = int(match.groups()[1])

                # pbar is initialized only when the first progress line is
                # found.
                if pbar is None:
                    pbar = tqdm(total=total, unit="objects")

                pbar.total = total
                pbar.update(done - done_before)

                done_before = done
            else:
                print(line, end="")
    except KeyboardInterrupt:
        pass
    finally:
        if pbar is not None:
            pbar.close()
