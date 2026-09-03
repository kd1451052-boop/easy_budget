import json, glob
import re

for f in glob.glob('lib/l10n/*.arb'):
    data = json.load(open(f))
    for k, v in data.items():
        if isinstance(v, str):
            # Check if there's a single quote that is not part of a double single quote
            # A single quote is valid in ICU ONLY if it's used for quoting, but usually
            # we need '' for a literal quote.
            # Let's just print any string with a single quote for manual review.
            if "'" in v:
                print(f"{f} [{k}]: {v}")
