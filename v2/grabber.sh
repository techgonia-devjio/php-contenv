#!/bin/bash

# ==============================================================================
# grabber.sh
#
# A robust script to create a snapshot of a directory structure and file
# contents into a single text file. It's useful for providing project context
# to LLMs or for creating a comprehensive text-based project archive.
#
# Author: Gemini
# Version: 1.0.1
# ==============================================================================

# --- Configuration: Default values ---
# These can be overridden by command-line arguments.
DEFAULT_PATH="."
DEFAULT_OUTPUT="directory_snapshot.txt"
# Common directories to ignore by default. Pipe-separated.
DEFAULT_IGNORE_DIRS=".git|node_modules|dist|build|target|vendor|__pycache__"
# Common file patterns/names to ignore by default. Pipe-separated.
DEFAULT_IGNORE_FILES="*.log|*.lock|*.env|package-lock.json|yarn.lock"

# --- Help Message Function ---
# Displays how to use the script.
show_help() {
    cat << EOF
Usage: $(basename "$0") [PATH] [OPTIONS]

Generates a snapshot of a directory, including a file tree and the contents of all
non-ignored files, into a single .txt file.

Arguments:
  PATH                  The path to the directory to scan.
                        (Default: current directory)

Options:
  --ignoreDir "dir1|dir2"   Pipe-separated list of directory names to ignore (case-insensitive).
                            (Default: "$DEFAULT_IGNORE_DIRS")
  --ignoreFiles "pat1|pat2" Pipe-separated list of file patterns to ignore (case-insensitive).
                            (Default: "$DEFAULT_IGNORE_FILES")
  --output "filename.txt"   The name for the output file.
                            (Default: "$DEFAULT_OUTPUT")
  -h, --help                Show this help message and exit.
EOF
}

# --- Argument Parsing ---
# Set variables from defaults
TARGET_PATH="$DEFAULT_PATH"
IGNORE_DIRS="$DEFAULT_IGNORE_DIRS"
IGNORE_FILES="$DEFAULT_IGNORE_FILES"
OUTPUT_FILE="$DEFAULT_OUTPUT"

# Handle the optional positional argument for the path first.
# This allows the user to specify the path without a flag, e.g., `grabber.sh /my/project`
if [[ -n "$1" && ! "$1" =~ ^-- && -d "$1" ]]; then
    TARGET_PATH="$1"
    shift # Consume the argument so the loop below doesn't see it
fi

# Loop through remaining arguments to parse options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --ignoreDir)
            IGNORE_DIRS="$2"
            shift; shift # Consume option and its value
            ;;
        --ignoreFiles)
            IGNORE_FILES="$2"
            shift; shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift; shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# --- Pre-flight Checks ---
# Ensure the 'tree' command is available, as it's crucial for the script.
if ! command -v tree &> /dev/null; then
    echo "Error: 'tree' command is not installed. Please install it to use this script." >&2
    echo "On Debian/Ubuntu: sudo apt-get install tree" >&2
    echo "On macOS (with Homebrew): brew install tree" >&2
    echo "On Fedora/CentOS: sudo dnf install tree" >&2
    exit 1
fi

# --- Main Script Logic ---
echo "Creating snapshot of '$TARGET_PATH'..."

# 1. Start with a clean output file and add a descriptive header.
# The curly braces group the commands to redirect their combined output to the file.
{
    echo "=================================================="
    echo " Directory Snapshot"
    echo "=================================================="
    echo "Source Path:   $(realpath "$TARGET_PATH")"
    echo "Generated on:  $(date)"
    echo "Ignored Dirs:  $IGNORE_DIRS"
    echo "Ignored Files: $IGNORE_FILES"
    echo "--------------------------------------------------"
    echo -e "\n### DIRECTORY TREE ###\n"
} > "$OUTPUT_FILE"

# 2. Generate and append the directory tree.
# -a: Show all files (including hidden ones).
# -F: Append indicators (/, *, @) to names.
# -I: Provide a pipe-separated pattern list to ignore.
# The combined ignore list is passed to tree.
# CRITICAL FIX: Add the output file itself to the ignore list.
tree -a -F -I "$IGNORE_DIRS|$IGNORE_FILES|$OUTPUT_FILE" "$TARGET_PATH" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE" # Add some space after the tree

# 3. Find all relevant files and append their content.
echo "Appending file contents..."

# Build the `find` command arguments dynamically to handle ignore patterns.
find_args=("$TARGET_PATH")

# CRITICAL FIX: Exclude the output file itself from being processed.
# We use -name for an exact match on the output file's name.
find_args+=(-not -name "$OUTPUT_FILE")

# Add directory ignore patterns to the find command arguments.
# We split the string by '|' into an array.
IFS='|' read -ra DIRS_TO_IGNORE <<< "$IGNORE_DIRS"
for dir in "${DIRS_TO_IGNORE[@]}"; do
    if [ -n "$dir" ]; then
        # Exclude paths containing the directory name and the directory itself.
        # -ipath and -iname are for case-insensitive matching.
        find_args+=(-not \( -ipath "*/$dir/*" -o -iname "$dir" \))
    fi
done

# Add file ignore patterns to the find command arguments.
IFS='|' read -ra FILES_TO_IGNORE <<< "$IGNORE_FILES"
for file in "${FILES_TO_IGNORE[@]}"; do
    if [ -n "$file" ]; then
        # Exclude files matching the pattern (case-insensitive).
        find_args+=(-not -iname "$file")
    fi
done

# Execute the find command and process each found file.
# -print0 and `read -d $'\0'` make this safe for filenames with spaces or special characters.
find "${find_args[@]}" -type f -print0 | while IFS= read -r -d $'\0' file; do
    # Get a cleaner, relative path for the file header.
    relative_path="${file#$TARGET_PATH/}"
    if [[ "$TARGET_PATH" == "." ]]; then
        relative_path="${file#./}"
    fi

    # Append the file's content with a clear header to the output file.
    {
        echo "---"
        echo -e "\n### FILE: $relative_path ###\n"
        # Using `cat` to add the file content.
        # The -vET flags can be useful to make non-printing characters visible,
        # preventing binary files from corrupting the output.
        # cat -vET "$file"
        cat "$file"
        echo "" # Ensure there's a newline at the end of the file content
    } >> "$OUTPUT_FILE"
done

# --- Finalization ---
echo "Snapshot complete! Output written to '$OUTPUT_FILE'."
echo "Total lines in output: $(wc -l < "$OUTPUT_FILE")"

