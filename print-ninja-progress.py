#!/usr/bin/python3
import sys
import re
from tqdm import tqdm

if __name__ == "__main__":
    bars = {}
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

                # Ideally, build-webkit would provide a hint of what task
                # this progress corresponds to, which I would use here.
                # Unfortunately this is not the case. build-webkit launches
                # several different tasks that write to the same file,
                # unidentified.
                # I use the "total" number as a name of sorts to differentiate
                # different processes. It's not perfect, but better than
                # nothing.
                bar_name = total

                # The bar is initialized only when the first progress line is
                # found.
                if bar_name not in bars:
                    bars[bar_name] = tqdm(total=total, unit="objs", ncols=80)

                if done > bars[bar_name].n:
                    # Advance the progress bar
                    bars[bar_name].update(done - bars[bar_name].n)

                if done == total:
                    # Finished with this bar
                    bars[bar_name].close()
                    del bars[bar_name]
            else:
                if len(bars) == 0:
                    print(line, end="", flush=True)
                else:
                    next(iter(bars.values())).write(line, end="")
    except KeyboardInterrupt:
        pass
