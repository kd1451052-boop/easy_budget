import os
import glob

files = glob.glob('lib/**/*.dart', recursive=True)
for f in files:
    with open(f, 'r') as file:
        content = file.read()
    if 'package:flutter_gen/gen_l10n/app_localizations.dart' in content:
        content = content.replace('package:flutter_gen/gen_l10n/app_localizations.dart', 'package:easy_budget/l10n/app_localizations.dart')
        with open(f, 'w') as file:
            file.write(content)
        print(f"Fixed {f}")
