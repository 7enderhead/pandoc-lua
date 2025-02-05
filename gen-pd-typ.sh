# Function to parse LUA_PATH
get_lua_paths() {
    local current_dir=$(pwd)
    IFS=';' read -ra PATHS <<< "$LUA_PATH"
    for path in "${PATHS[@]}"; do
        # Remove '?.lua' pattern and trim whitespace
        dir=$(echo "$path" | sed 's/?.lua//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # If dir is empty, use current directory
        if [ -z "$dir" ]; then
            dir="$current_dir"
        else
            # Expand user home directory if present
            dir="${dir/#\~/$HOME}"
        fi
        # Convert to absolute path
        dir=$(readlink -f "$dir")
        echo "$dir"
    done | sort -u  # Sort and remove duplicates
}

# Function to list Lua files with a specific prefix and store them in an array
get_lua_files() {
    local dir="$1"
    local prefix="$2"
    local -n result_array="$3"  # Use nameref for the result array

    if [ -d "$dir" ]; then
        while IFS= read -r -d '' file; do
            result_array+=("$file")
        done < <(find "$dir" -type f -name "${prefix}*.lua" -print0 2>/dev/null)
    fi
}

# Put all "cE-pdfilter"
get_all_lua_filters(){
    local -n paths=$1
    readarray -t lua_paths < <(get_lua_paths)
    for dir in "${lua_paths[@]}"; do
        results=()
        get_lua_files "${dir}" "cE-pdfilter-" results
        paths+=("${results[@]}")
    done
    IFS=$'\n'
    readarray -t paths < <(
        for path in "${paths[@]}"; do
            echo "$(basename "$path")|$path"
        done | sort -f | cut -d'|' -f2-
    )
}

file_exists_in_paths() {
    local basename="$1"
    shift
    local paths=("$@")

    for path in "${paths[@]}"; do
        if [ -f "$path/$basename" ]; then
            echo "$path/$basename"
            return 0
        fi
    done

    return 1
}

if [ $# -ne 1 ] || [ -z "$1" ]; then
    echo "Usage: $0 'basename of file to generate'" >&2
    exit 1
fi

declare -a all_filters
get_all_lua_filters all_filters

pandoc_filter_prefix="--lua-filter "
pandoc_filter_string=$(printf -- "${pandoc_filter_prefix}%s " "${all_filters[@]}")
inotify_prefix="-f "
inotify_filter_string=$(printf -- "${inotify_prefix}%s " "${all_filters[@]}")

current_path=$(pwd -P)
script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
paths=("${current_path}" "${script_path}")

if typst_template=$(file_exists_in_paths "cE.typ.template" "${paths[@]}"); then
    template_string="--template=${typst_template}"
    inotify_template_string="-f ${typst_template}"
fi

if typst_metadata=$(file_exists_in_paths "cE.typ.yaml" "${paths[@]}"); then
    metadata_string="--metadata-file=${typst_metadata}"
    inotify_metadata_string="-f ${typst_metadata}"
fi

base_name=$1
md_file="${base_name}.md"
typst_file="${base_name}.typ"

pandoc_command="pandoc -f markdown+smart ${template_string} ${metadata_string} ${pandoc_filter_string} -o ${typst_file} ${md_file}"
inotify_command="inotify-hookable -f ${md_file} ${inotify_template_string} ${inotify_metadata_string} ${inotify_filter_string} -c \"${pandoc_command}\""

echo "Base file name: '${base_name}'"
echo "Markdown file: '${md_file}'"
echo "Typst file: '${typst_file}'"
echo "Typst template file: '${typst_template}'"
echo "Typst metadata file: '${typst_metadata}'"
echo "Pandoc command: '${pandoc_command}'"
echo "Inotify command: '${inotify_command}'"



pandoc_watch() {
    eval ${pandoc_command} # initial run
    eval ${inotify_command} # watching subsequent changes
}

typst_watch() {
    typst watch ${typst_file}
}

echo -n "Starting watch on pandoc files... "
pandoc_watch &
pid_pandoc_watch=$!
echo "done, PID is '${pid_pandoc_watch}'."

echo -n "Starting watch on Typst file... "
typst_watch &
pid_typst_watch=$!
echo "done, PID is '${pid_pandoc_watch}'."

trap cleanup SIGINT

cleanup() {
    echo -n "Terminating pandoc watch... "
    kill ${pid_pandoc_watch}
    echo "done."

    echo -n "Terminating Typst watch... "
    kill ${pid_typst_watch}
    echo "done."
}

wait ${pid_pandoc_watch} ${pid_typst_watch}