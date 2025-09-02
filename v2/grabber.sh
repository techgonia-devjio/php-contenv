#!/bin/bash

# usage:  ./grabber.sh . --ignoreDir ".git|.venv|.container-history" --ignoreFiles "*.txt|LICENSE|grabber.sh" --output "snapshot.txt"
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

## ----- Main Execution -----

echo "Creating snapshot of '$TARGET_PATH'..."

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

tree -a -F -I "$IGNORE_DIRS|$IGNORE_FILES|$OUTPUT_FILE" "$TARGET_PATH" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Appending file contents..."

find_args=("$TARGET_PATH")

find_args+=(-not -name "$OUTPUT_FILE")

IFS='|' read -ra DIRS_TO_IGNORE <<< "$IGNORE_DIRS"
for dir in "${DIRS_TO_IGNORE[@]}"; do
    if [ -n "$dir" ]; then
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

find "${find_args[@]}" -type f -print0 | while IFS= read -r -d $'\0' file; do
    relative_path="${file#$TARGET_PATH/}"
    if [[ "$TARGET_PATH" == "." ]]; then
        relative_path="${file#./}"
    fi

    {
        echo "---"
        echo -e "\n### FILE: $relative_path ###\n"
        cat "$file"
        echo "" # Ensure there's a newline at the end of the file content
    } >> "$OUTPUT_FILE"
done

# --- Finalization ---
echo "Snapshot complete! Output written to '$OUTPUT_FILE'."
echo "Total lines in output: $(wc -l < "$OUTPUT_FILE")"

