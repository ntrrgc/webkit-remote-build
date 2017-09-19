#!/usr/bin/python3
import sys
import re
from tqdm import tqdm

if __name__ == "__main__":
    bar = None
    re_progress = re.compile(r"^\[(\d+)/(\d+)\] ")

    try:
        for line in sys.stdin:
            match = re_progress.match(line)
            if match:
                done = int(match.groups()[0])
                total = int(match.groups()[1])

                if total <= 1:
                    # Ignore short tasks
                    continue

                if bar is not None and (done < bar.n or total != bar.total):
                    # If the progress goes backwards or the total changes,
                    # destroy the current bar and draw a new one.
                    bar.leave = False
                    bar.close()
                    bar = None

                # The bar is initialized only when the first progress line is
                # found.
                if bar is None:
                    bar = tqdm(total=total, unit="objs", ncols=80)

                if done > bar.n:
                    # Advance the progress bar
                    bar.update(done - bar.n)

                if done == total:
                    # Finished with this bar
                    bar.close()
                    bar = None
            else:
                if bar is None:
                    print(line, end="", flush=True)
                else:
                    bar.write(line, end="")
    except KeyboardInterrupt:
        pass
