#!/bin/bash

# ---- privilege escalation ----
if [[ "$EUID" -ne 0 ]]; then
    echo -e "\033[1;33m[INFO] Re-running with sudo...\033[0m"
    exec sudo "$0" "$@"
fi

# Define paths
APP_PATH="/Applications/Antigravity.app/Contents/Resources/app/out/main.js"
BACKUP_PATH="${APP_PATH}.bak"
TMP_FILE="/tmp/antigravity_main_patch.js"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Antigravity UNIVERSAL UNLOCKER (v3 - All Emails) ===${NC}"
echo -e "Target file: $APP_PATH"

if [ ! -f "$APP_PATH" ]; then
    echo -e "${RED}[ERROR] File not found!${NC}"
    echo "Check if Antigravity is installed in /Applications."
    exit 1
fi

echo -e "${YELLOW}[INFO] Copying file to temp location (SIP bypass)...${NC}"
cp "$APP_PATH" "$TMP_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to copy file to /tmp${NC}"
    exit 1
fi

xattr -cr "$TMP_FILE" 2>/dev/null
chmod 644 "$TMP_FILE" 2>/dev/null

if [ ! -f "$BACKUP_PATH" ]; then
    echo -e "${YELLOW}[INFO] Creating backup...${NC}"
    cp "$APP_PATH" "$BACKUP_PATH" 2>/dev/null || echo -e "${YELLOW}[WARN] Could not create backup${NC}"
fi

echo -e "${YELLOW}[INFO] Applying patch (Feature Unlock only)...${NC}"
python3 - "$TMP_FILE" <<'PYEOF'
import sys
import os
import re

try:
    target_path = sys.argv[1]

    with open(target_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove old email-checking patch if present (from previous versions)
    content = re.sub(r'(?s)import \{ createRequire.*?\}\)\(\);\s*', '', content)
    content = content.strip()

    # Detect Antigravity version from product.json (informational)
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
                func_name = last.group(1)
                arg_name = last.group(2)
                ctx_prop = last.group(3)

                actual_start = region_start + last.start()

                # Find end of the function
                after_end = end_idx + len(end_anchor)
                closing = content[after_end:after_end+10]
                extra = 0
                for ch in closing:
                    extra += 1
                    if ch == '}' and '}}' in closing[:extra]:
                        break
                func_end = after_end + extra

                original_func = content[actual_start:func_end]

                # Extract dynamic property names from the original function
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
                    replacement = (
                        f'async {func_name}({t}){{console.log("[HACK] FORCE LOGIN");'
                        f'if(this.{ctx_prop}.isGoogleInternal){{try{{await this.{svc}.loadCodeAssist({t});'
                        f'const{{settings:n,userTier:a}}=await this.refreshUserStatus({t}),_s={push_helper}({t});this.{push}.pushUpdate(_s),this.{evt}.fire({{settings:n,userTier:a}})}}catch(_){{}}return}}'
                        f'try{{try{{await this.{svc}.loadCodeAssist({t})}}catch(_){{}}'
                        f'this.{evt}.fire({{oauthTokenInfo:{t}}});'
                        f'try{{await this.{svc}.onboardUser("standard-tier",{t})}}catch(_){{'
                        f'try{{await this.{svc}.onboardUser("free-tier",{t})}}catch(__){{}}}}'
                        f'try{{const{{settings:p,userTier:g}}=await this.refreshUserStatus({t}),_b={push_helper}({t});this.{push}.pushUpdate(_b),this.{evt}.fire({{settings:p,userTier:g}})}}catch(_){{}}'
                        f'console.log("[HACK] DONE")}}catch(n){{this.{evt}.fire({{oauthTokenInfo:{t}}})}}}}'
                    )
                else:
                    replacement = (
                        f'async {func_name}({t}){{console.log("[HACK] FORCE LOGIN");'
                        f'if(this.{ctx_prop}.isGoogleInternal){{try{{await this.{svc}.loadCodeAssist({t});'
                        f'const{{settings:n,userTier:a}}=await this.refreshUserStatus({t});this.{evt}.fire({{settings:n,userTier:a}})}}catch(_){{}}return}}'
                        f'try{{try{{await this.{svc}.loadCodeAssist({t})}}catch(_){{}}'
                        f'this.{evt}.fire({{oauthTokenInfo:{t}}});'
                        f'try{{await this.{svc}.onboardUser("standard-tier",{t})}}catch(_){{'
                        f'try{{await this.{svc}.onboardUser("free-tier",{t})}}catch(__){{}}}}'
                        f'try{{const{{settings:p,userTier:g}}=await this.refreshUserStatus({t});this.{evt}.fire({{settings:p,userTier:g}})}}catch(_){{}}'
                        f'console.log("[HACK] DONE")}}catch(n){{this.{evt}.fire({{oauthTokenInfo:{t}}})}}}}'
                    )

                content = content[:actual_start] + replacement + content[func_end:]
                unlock_applied = True
            else:
                print('[WARN] Could not parse auth function signature.')
        else:
            print('[WARN] Auth anchor not found. Feature unlock may not be applied.')

    with open(target_path, 'w', encoding='utf-8') as f:
        f.write(content)

    if unlock_applied:
        print(f'[INFO] Feature Unlock applied (Dynamic Method v{ag_version}).')
    print('[INFO] Patch applied to temp file.')

except Exception as e:
    print(f'[ERROR] Python error: {e}')
    sys.exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Python patching failed${NC}"
    rm -f "$TMP_FILE"
    exit 1
fi

echo -e "${YELLOW}[INFO] Copying patched file back...${NC}"

cp "$TMP_FILE" "$APP_PATH" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] Patched file copied successfully!${NC}"
else
    echo -e "${YELLOW}[INFO] Direct copy failed, trying alternative method...${NC}"
    cat "$TMP_FILE" > "$APP_PATH" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Patched file written successfully (alt method)!${NC}"
    else
        echo -e "${RED}[ERROR] Could not write patched file back.${NC}"
        echo "Patched file saved in: $TMP_FILE"
        echo "Try manually: sudo cp $TMP_FILE $APP_PATH"
        exit 1
    fi
fi

rm -f "$TMP_FILE"

echo -e "${YELLOW}[INFO] Repairing app signature...${NC}"
xattr -cr "/Applications/Antigravity.app" 2>/dev/null
codesign --force --deep --sign - "/Applications/Antigravity.app" 2>/dev/null

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}[SUCCESS] Licensed to: All emails (unlocked)${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${CYAN}Please restart Antigravity IDE.${NC}"
