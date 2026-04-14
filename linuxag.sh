#!/bin/bash

# Dynamic Linux Patch (All Emails)

PATHS=(
    "/opt/Antigravity/resources/app/out/main.js"
    "/usr/lib/antigravity/resources/app/out/main.js"
    "/usr/share/antigravity/resources/app/out/main.js"
    "$HOME/Antigravity/resources/app/out/main.js"
)

APP_PATH=""
for path in "${PATHS[@]}"; do
    if [ -f "$path" ]; then
        APP_PATH="$path"
        break
    fi
done

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Antigravity UNIVERSAL UNLOCKER (v3 - All Emails) ===${NC}"

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}[ERROR] Target file not found!${NC}"
    echo "Checked:"
    for path in "${PATHS[@]}"; do echo " - $path"; done
    exit 1
fi

echo -e "Target file: $APP_PATH"
BACKUP_PATH="${APP_PATH}.bak"

if [ ! -w "$APP_PATH" ]; then
    echo -e "${YELLOW}[WARN] Write permission denied. Re-running with sudo...${NC}"
    sudo "$0"
    exit
fi

python3 - "$APP_PATH" <<'PYEOF'
import sys
import os
import shutil
import re

try:
    target_path = sys.argv[1]
    backup_path = target_path + '.bak'

    with open(target_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove old email-checking patch if present
    content = re.sub(r'(?s)import \{ createRequire.*?\}\)\(\);\s*', '', content)
    content = content.strip()

    # Detect version (informational)
    app_dir = os.path.dirname(os.path.dirname(target_path))
    prod_path = os.path.join(app_dir, 'product.json')
    ag_version = 'unknown'
    if os.path.exists(prod_path):
        try:
            import json
            with open(prod_path, 'r') as pf:
                prod = json.load(pf)
                ag_version = prod.get('ideVersion', prod.get('version', 'unknown'))
        except: pass

    # DYNAMIC Feature Unlock (no email restrictions)
    unlock_applied = False

    if '[HACK] FORCE LOGIN' in content:
        print('[INFO] Feature Unlock already present.')
        unlock_applied = True

    if not unlock_applied:
        end_anchor = '"only sensitiveData may contain user data"'
        end_idx = content.find(end_anchor)

        if end_idx > 0:
            search_back = 5000
            region_start = max(0, end_idx - search_back)
            region = content[region_start:end_idx]

            func_matches = list(re.finditer(r'async\s+(\w+)\((\w+)\)\{if\([^{]*?this\.(\w+)\.isGoogleInternal\)', region))

            if func_matches:
                last = func_matches[-1]
                func_name, arg_name, ctx_prop = last.group(1), last.group(2), last.group(3)
                actual_start = region_start + last.start()

                after_end = end_idx + len(end_anchor)
                closing = content[after_end:after_end+10]
                extra = 0
                for ch in closing:
                    extra += 1
                    if ch == '}' and '}}' in closing[:extra]:
                        break
                func_end = after_end + extra
                original_func = content[actual_start:func_end]

                svc_m = re.search(r'this\.(\w+)\.loadCodeAssist', original_func)
                svc = svc_m.group(1) if svc_m else 't'
                evt_m = re.search(r'this\.(\w+)\.fire\(', original_func)
                evt = evt_m.group(1) if evt_m else 'h'
                push_m = re.search(r'this\.(\w+)\.pushUpdate', original_func)
                push = push_m.group(1) if push_m else 'z'
                helper_m = re.search(r'=(\w+)\(\w+\);this\.\w+\.pushUpdate', original_func)
                push_helper = helper_m.group(1) if helper_m else ''

                t = arg_name
                if push_helper:
                    replacement = f'async {func_name}({t}){{console.log("[HACK] FORCE LOGIN");if(this.{ctx_prop}.isGoogleInternal){{try{{await this.{svc}.loadCodeAssist({t});const{{settings:n,userTier:a}}=await this.refreshUserStatus({t}),_s={push_helper}({t});this.{push}.pushUpdate(_s),this.{evt}.fire({{settings:n,userTier:a}})}}catch(_){{}}return}}try{{try{{await this.{svc}.loadCodeAssist({t})}}catch(_){{}}this.{evt}.fire({{oauthTokenInfo:{t}}});try{{await this.{svc}.onboardUser("standard-tier",{t})}}catch(_){{try{{await this.{svc}.onboardUser("free-tier",{t})}}catch(__){{}}}}try{{const{{settings:p,userTier:g}}=await this.refreshUserStatus({t}),_b={push_helper}({t});this.{push}.pushUpdate(_b),this.{evt}.fire({{settings:p,userTier:g}})}}catch(_){{}}console.log("[HACK] DONE")}}catch(n){{this.{evt}.fire({{oauthTokenInfo:{t}}})}}}}'
                else:
                    replacement = f'async {func_name}({t}){{console.log("[HACK] FORCE LOGIN");if(this.{ctx_prop}.isGoogleInternal){{try{{await this.{svc}.loadCodeAssist({t});const{{settings:n,userTier:a}}=await this.refreshUserStatus({t});this.{evt}.fire({{settings:n,userTier:a}})}}catch(_){{}}return}}try{{try{{await this.{svc}.loadCodeAssist({t})}}catch(_){{}}this.{evt}.fire({{oauthTokenInfo:{t}}});try{{await this.{svc}.onboardUser("standard-tier",{t})}}catch(_){{try{{await this.{svc}.onboardUser("free-tier",{t})}}catch(__){{}}}}try{{const{{settings:p,userTier:g}}=await this.refreshUserStatus({t});this.{evt}.fire({{settings:p,userTier:g}})}}catch(_){{}}console.log("[HACK] DONE")}}catch(n){{this.{evt}.fire({{oauthTokenInfo:{t}}})}}}}'

                content = content[:actual_start] + replacement + content[func_end:]
                unlock_applied = True
            else:
                print('[WARN] Could not parse auth function signature.')
        else:
            print('[WARN] Auth anchor not found. Feature unlock may not be applied.')

    print('[INFO] Creating backup...')
    shutil.copy2(target_path, backup_path)

    print('[INFO] Writing patch...')
    with open(target_path, 'w', encoding='utf-8') as f:
        f.write(content)

    if unlock_applied:
        print(f'[INFO] Feature Unlock applied (Dynamic Method v{ag_version}).')
    print('[SUCCESS] Licensed to: All emails (unlocked)')
    print('Please restart Antigravity IDE.')

except Exception as e:
    print(f'[ERROR] An error occurred: {e}')
    sys.exit(1)
PYEOF
