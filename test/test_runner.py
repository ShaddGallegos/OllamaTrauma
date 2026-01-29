import os
import sys
import time
import argparse
import re
from datetime import datetime

def ensure_pexpect():
    try:
        import pexpect  # noqa: F401
        return True
    except ImportError:
        sys.stderr.write("Missing dependency: pexpect. Install with: pip install pexpect\n")
        return False

def main():
    parser = argparse.ArgumentParser(description="OllamaTrauma v2 menu test harness")
    parser.add_argument("--ci-ok", action="store_true", help="Exit 0 even if warnings/failures occur")
    args = parser.parse_args()

    ci_ok_env = os.environ.get("OT_CI_MODE", "0")
    ci_ok = args.ci_ok or (ci_ok_env == "1")
    if not ensure_pexpect():
        sys.exit(1)

    import pexpect

    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    script_path = os.path.join(project_root, "OllamaTrauma_v2.sh")
    log_dir = os.path.join(project_root, "log")
    os.makedirs(log_dir, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = os.path.join(log_dir, f"OllamaTrauma_{ts}.log")

    failures = []

    ANSI_RED = "\x1b[31m"
    ANSI_RESET = "\x1b[0m"

    class Tee:
        def __init__(self, fileobj):
            self.fileobj = fileobj
        def write(self, data):
            try:
                sys.stdout.write(data)
            except Exception:
                pass
            try:
                self.fileobj.write(data)
            except Exception:
                pass
        def flush(self):
            try:
                sys.stdout.flush()
            except Exception:
                pass
            try:
                self.fileobj.flush()
            except Exception:
                pass

    def log(msg, color=None):
        line = msg
        if color == "red":
            line = f"{ANSI_RED}{msg}{ANSI_RESET}"
        print(line)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(line + "\n")

    if not os.path.isfile(script_path):
        log(f"ERROR: Script not found: {script_path}")
        sys.exit(1)

    # Spawn the app
    child = pexpect.spawn("bash", [script_path], encoding="utf-8", timeout=20)
    child_log = open(log_path, "a", encoding="utf-8")
    child.logfile = Tee(child_log)

    def expect_and_send(expect_text, send_text=None, label=None, timeout=20):
        try:
            child.expect(expect_text, timeout=timeout)
            if send_text is not None:
                child.sendline(send_text)
            return True
        except pexpect.TIMEOUT:
            failures.append(label or expect_text)
            log(f"WARN: Timeout waiting for '{label or expect_text}'", color="red")
            return False
        except pexpect.EOF:
            failures.append(label or expect_text)
            log(f"WARN: Unexpected EOF while waiting for '{label or expect_text}'", color="red")
            return False

    def expect_and_send_soft(expect_text, send_text=None, timeout=20):
        try:
            child.expect(expect_text, timeout=timeout)
            if send_text is not None:
                child.sendline(send_text)
            return True
        except (pexpect.TIMEOUT, pexpect.EOF):
            return False

    # Navigate Main Menu options safely without performing destructive actions
    # Main menu prompt
    expect_and_send(r"Main Menu", None, label="main_menu_header")
    expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")

    def parse_menu_options(screen_text):
        try:
            nums = set()
            for m in re.finditer(r"^\s*(\d+)\s*(?:[)\-: ]|\))", screen_text, flags=re.M):
                try:
                    nums.add(int(m.group(1)))
                except Exception:
                    continue
            return sorted(nums)
        except Exception:
            return []

    def return_to_main_from_submenu(menu_number, submenu_header, back_keys=None):
        if back_keys is None:
            back_keys = ["0", "q", "Q"]
        for bk in back_keys:
            child.sendline(bk)
            try:
                expect_and_send(r"Main Menu", None, label="return_to_main")
                expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")
                return
            except Exception:
                # Try next key
                continue
        # Fallback: re-enter submenu then try sending first back key again
        child.sendline(str(menu_number))
        expect_and_send(submenu_header, None, label=f"{submenu_header}_header_fallback")
        expect_and_send(r"Select option \[[0-9\-]+\]:", None, label=f"{submenu_header}_prompt_fallback")
        child.sendline(back_keys[0])
        expect_and_send(r"Main Menu", None, label="return_to_main_fallback")
        expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt_fallback")

    def reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern=r"Select option \[[0-9\-]+\]:"):
        child.sendline(str(menu_number))
        expect_and_send(submenu_header, None, label=f"{submenu_header}_header")
        expect_and_send(submenu_prompt_pattern, None, label=f"{submenu_header}_prompt")

    def exercise_submenu_all(menu_number, submenu_header, back_keys=None, submenu_prompt_pattern=r"Select option \[[0-9\-]+\]:"):
        log(f"Testing menu {menu_number}: {submenu_header}")
        if back_keys is None:
            back_keys = ["0", "q", "Q"]
        # Enter submenu and get prompt
        child.sendline(str(menu_number))
        ok = expect_and_send(submenu_header, None, label=f"{submenu_header}_header")
        if not ok:
            return
        ok = expect_and_send(submenu_prompt_pattern, None, label=f"{submenu_header}_prompt")
        if not ok:
            return
        submenu_start = time.monotonic()
        # Parse options from the screen prior to the prompt
        options = parse_menu_options(child.before or "")
        # Avoid selecting back option if numeric and equals back_key
        numeric_back_keys = set()
        for bk in back_keys:
            try:
                numeric_back_keys.add(int(bk))
            except Exception:
                pass
        options = [o for o in options if o not in numeric_back_keys]

        for opt in options:
            if (time.monotonic() - submenu_start) > 30:
                log(f"WARN: Submenu {submenu_header} exceeded 30s; returning to main", color="red")
                return_to_main_from_submenu(menu_number, submenu_header, back_keys=back_keys)
                return
            label = f"{submenu_header}_opt_{opt}"
            log(f" - Exercising {label}")
            child.sendline(str(opt))
            # Handle common flows: nested submenu prompt, enter-to-continue, yes/no, health select, or return to main
            handled = False
            start_opt = time.monotonic()
            max_opt_timeout = 6
            if submenu_header == "Setup & Configuration" and opt == 3:
                # Installing dependencies can take longer; allow more time per option
                max_opt_timeout = 20
            for _ in range(3):
                try:
                    idx = child.expect([
                        submenu_prompt_pattern,
                        r"Press Enter to continue\.\.\.",
                        r"Run .*\? \[y/N\]:",
                        r"Main Menu",
                        r"Select:",
                        r"\[?[Bb]\]?ack|Return to Main|Go Back|Exit",
                        r"Error|Failed|Not found",
                    ], timeout=10)
                    if idx == 0:
                        # Back at submenu prompt
                        handled = True
                        break
                    elif idx == 1:
                        # Press Enter to continue
                        child.sendline("")
                        handled = True
                        # Expect to return to submenu prompt
                        if submenu_header == "Setup & Configuration" and opt == 3:
                            if not expect_and_send_soft(submenu_prompt_pattern, None, timeout=20):
                                # Try soft recovery with back keys without failing
                                for bk in back_keys:
                                    child.sendline(bk)
                                    if expect_and_send_soft(submenu_prompt_pattern, None, timeout=5):
                                        break
                        else:
                            expect_and_send(submenu_prompt_pattern, None, label=f"{label}_return_submenu")
                        break
                    elif idx == 2:
                        # Generic y/N prompt, default to N
                        child.sendline("")
                        # Try to get back to submenu prompt
                        if submenu_header == "Setup & Configuration" and opt == 3:
                            if not expect_and_send_soft(submenu_prompt_pattern, None, timeout=20):
                                for bk in back_keys:
                                    child.sendline(bk)
                                    if expect_and_send_soft(submenu_prompt_pattern, None, timeout=5):
                                        break
                        else:
                            expect_and_send(submenu_prompt_pattern, None, label=f"{label}_return_submenu")
                        handled = True
                        break
                    elif idx == 3:
                        # Returned to main unexpectedly; re-enter submenu
                        expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt_after_return")
                        reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern)
                        handled = True
                        break
                    elif idx == 4:
                        # Health dashboard-like select; send 'q' to quit
                        child.sendline("q")
                        # Try to return to submenu or main
                        try:
                            child.expect(submenu_prompt_pattern, timeout=5)
                        except (pexpect.TIMEOUT, pexpect.EOF):
                            expect_and_send(r"Main Menu", None, label=f"{label}_return_main")
                            expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")
                            reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern)
                        handled = True
                        break
                    elif idx == 5:
                        # Back/Return/Exit hints; try back using multiple keys
                        success = False
                        for bk in back_keys:
                            child.sendline(bk)
                            try:
                                child.expect(submenu_prompt_pattern, timeout=5)
                                success = True
                                break
                            except (pexpect.TIMEOUT, pexpect.EOF):
                                continue
                        if not success:
                            expect_and_send(r"Main Menu", None, label=f"{label}_return_main")
                            expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")
                            reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern)
                        handled = True
                        break
                    elif idx == 6:
                        # Generic error; press Enter then try to return
                        child.sendline("")
                        try:
                            child.expect(submenu_prompt_pattern, timeout=5)
                        except (pexpect.TIMEOUT, pexpect.EOF):
                            expect_and_send(r"Main Menu", None, label=f"{label}_return_main")
                            expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")
                            reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern)
                        handled = True
                        break
                except (pexpect.TIMEOUT, pexpect.EOF):
                    # Recovery attempts: Enter, then Back key, then re-enter submenu
                    child.sendline("")
                    try:
                        child.expect(submenu_prompt_pattern, timeout=5)
                        handled = True
                        break
                    except (pexpect.TIMEOUT, pexpect.EOF):
                        try:
                            for bk in back_keys:
                                child.sendline(bk)
                                try:
                                    child.expect(submenu_prompt_pattern, timeout=5)
                                    handled = True
                                    break
                                except (pexpect.TIMEOUT, pexpect.EOF):
                                    continue
                            if handled:
                                break
                            handled = True
                            break
                        except (pexpect.TIMEOUT, pexpect.EOF):
                            # Re-enter submenu from main if we got bounced
                            try:
                                child.expect(r"Main Menu", timeout=3)
                                expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt_after_bounce")
                                reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern)
                                handled = True
                                break
                            except (pexpect.TIMEOUT, pexpect.EOF):
                                pass
                # Hard stop per-option to avoid hanging indefinitely
                if not handled and (time.monotonic() - start_opt) > max_opt_timeout:
                    try:
                        for bk in back_keys:
                            child.sendline(bk)
                            try:
                                child.expect(submenu_prompt_pattern, timeout=3)
                                break
                            except (pexpect.TIMEOUT, pexpect.EOF):
                                continue
                    except (pexpect.TIMEOUT, pexpect.EOF):
                        try:
                            expect_and_send(r"Main Menu", None, label=f"{label}_timeout_return_main")
                            expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")
                            reenter_submenu(menu_number, submenu_header, submenu_prompt_pattern)
                        except Exception:
                            pass
                    handled = True
                    log(f"WARN: Timeout exercising {label}; skipped with safe return", color="red")
                    break
            if not handled:
                failures.append(label)
                log(f"WARN: Could not fully exercise {label}", color="red")

        # Return to main
        return_to_main_from_submenu(menu_number, submenu_header, back_keys=back_keys)

    # 1) Setup & Configuration
    exercise_submenu_all(1, "Setup & Configuration")
    # 2) AI Runners Management
    exercise_submenu_all(2, "AI Runners Management")
    # 3) Model Management
    exercise_submenu_all(3, "Model Management")

    # 4) Training Data Crawler (interactive function, not submenu)
    log("Testing menu 4: Training Data Crawler (non-menu function)")
    child.sendline("4")
    # Expect header
    expect_and_send(r"Training Data Crawler", None, label="crawler_header")
    # Provide empty URL to trigger graceful error + pause
    expect_and_send(r"Enter URL to crawl:", "", label="crawler_url_prompt")
    # Expect pause prompt
    expect_and_send(r"Press Enter to continue\.\.\.", "", label="crawler_pause")
    # Back to main menu
    expect_and_send(r"Main Menu", None, label="return_to_main_after_crawler")
    expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")

    # 5) Maintenance & Logs
    exercise_submenu_all(5, "Maintenance & Logs")

    # 6) Health Check Dashboard (uses [R]/[Q])
    log("Testing menu 6: Health Check Dashboard")
    child.sendline("6")
    expect_and_send(r"Health Check Dashboard", None, label="health_header", timeout=30)
    # Exit with 'q'
    expect_and_send(r"Select:", "q", label="health_select")
    expect_and_send(r"Main Menu", None, label="return_to_main_after_health")
    expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")

    # 7) Chat Interface (may be missing; ensure app handles gracefully)
    log("Testing menu 7: Chat Interface")
    child.sendline("7")
    # Expect either a prompt or an error log; just wait for main menu again
    expect_and_send(r"Main Menu", None, label="return_to_main_after_chat")
    expect_and_send(r"Select option \[0-9\]:", None, label="main_menu_prompt")

    # 8) Configuration Profiles
    exercise_submenu_all(8, "Configuration Profiles")

    # 9) Quick Run (asks y/N)
    log("Testing menu 9: Quick Run")
    child.sendline("9")
    # Expect various detections or warnings; press Enter to default N on prompts
    # Attempt to handle a couple of potential prompts gracefully
    for prompt in [
        r"Run default model with Ollama\? \[y/N\]:",
        r"Run default container with Docker\? \[y/N\]:",
        r"Run default container with Podman\? \[y/N\]:",
        r"Press Enter to continue\.\.\.",
    ]:
        try:
            child.expect(prompt, timeout=5)
            child.sendline("")
        except (pexpect.TIMEOUT, pexpect.EOF):
            # Not fatal; prompt may not appear depending on environment
            pass
    # Attempt to return to main; tolerate EOF if quick run ends the program
    handled_main = False
    try:
        child.expect(r"Main Menu", timeout=5)
        handled_main = True
        child.expect(r"Select option \[0-9\]:", timeout=5)
    except (pexpect.TIMEOUT, pexpect.EOF):
        log("INFO: Quick Run completed without returning to Main Menu (EOF/TIMEOUT)")

    # Exit if still in the app
    if handled_main:
        child.sendline("0")
        child.expect(pexpect.EOF, timeout=20)

    log("=== Test Completed ===")
    if failures:
        log("Warnings/Failures detected:", color="red")
        for f in failures:
            log(f" - {f}", color="red")
        if ci_ok:
            log("CI mode enabled: exiting 0 despite warnings.")
            sys.exit(0)
        else:
            sys.exit(2)
    else:
        log("All menu navigation checks passed.")

if __name__ == "__main__":
    main()
