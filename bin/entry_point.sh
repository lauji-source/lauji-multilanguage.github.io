#!/bin/bash
set -euo pipefail

echo "Entry point script running"

CONFIG_FILE=_config.yml

# Function to manage Gemfile.lock
manage_gemfile_lock() {
    git config --global --add safe.directory '*'
    if command -v git &> /dev/null && [ -f Gemfile.lock ]; then
        if git ls-files --error-unmatch Gemfile.lock &> /dev/null; then
            echo "Gemfile.lock is tracked by git, keeping it intact"
            git restore Gemfile.lock 2>/dev/null || true
        else
            echo "Gemfile.lock is not tracked by git, removing it"
            rm Gemfile.lock
        fi
    fi
}

start_jekyll() {
    manage_gemfile_lock
    bundle exec jekyll serve --watch --port=4000 --host=0.0.0.0 --livereload --verbose --trace --force_polling &
}

start_jekyll

while true; do
# The inotifywait command is used to monitor a specified file for any modifications. The -q option makes the program run in quiet mode, so it only outputs messages when an event occurs rather than continuously monitoring. The -e modify,move,create,delete part tells it to watch for four specific events: if the file’s contents change (modify), if it is moved or copied (move), if a new file is created next to it (create), or if it is removed (delete). By passing $CONFIG_FILE as an argument, the script watches that particular configuration file.
# When any of these events happen, the command signals the event to the bash loop running in the entry point script. The script then restarts Jekyll by killing the existing jekyll process and relaunching it with bundle exec jekyll serve. This ensures that any change to the config triggers an immediate rebuild and live‑reloading of the site.
    inotifywait -q -e modify,move,create,delete $CONFIG_FILE
    if [ $? -eq 0 ]; then
        echo "Change detected to $CONFIG_FILE, restarting Jekyll"
        jekyll_pid=$(pgrep -f jekyll)
        kill -KILL $jekyll_pid
        start_jekyll
    fi
done
