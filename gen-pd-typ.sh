ini_log() {
    echo "Invocation of ${script_name} on $(date '+%Y-%m-%d %H:%M:%S')" > ${log_file}
}

log() {
    local message="$1"
    echo ${message} >> ${log_file}
}

log_array() {
    local description="$1"
    shift
    local -a array=("$@")
    log "${description}"
    for element in "${array[@]}"; do
        log "'${element}'"
    done
}

current_path=$(pwd -P)
parent_path=$(dirname "$PWD")
script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
script_name=$(basename "${BASH_SOURCE[0]}")
log_file="${PWD}/${script_name}.log"
pandoc_log_file="${PWD}/${script_name}.pandoc.log"

ini_log

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
            echo ${file}
            result_array+=("$file")
        done < <(find "$dir" -type f -name "${prefix}*.lua" -print0 2>/dev/null)
    fi
}

# Put all "cE-pdfilter"
get_all_lua_filters() {
    local -n filter_search_paths=$1
    local -n filter_results=$2
    for path in "${filter_search_paths[@]}"; do
        filters_in_path=()
        get_lua_files "${path}" "cE-pdfilter-" filters_in_path
        filter_results+=("${filters_in_path[@]}")
    done
    # sort results alphabetically by filename
    IFS=$'\n'
    readarray -t results < <(
        for path in "${filter_results[@]}"; do
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

prefix_array() {
    local prefix="$1"
    shift
    local result=""
    for element in "$@"; do
        result+="${prefix}'${element}' "
    done
    echo "${result% }"
}

if [ $# -ne 1 ] || [ -z "$1" ]; then
    echo "Usage: $0 'basename of file to generate'" >&2
    exit 1
fi

paths=("${current_path}" "${parent_path}" "${script_path}" $(get_lua_paths))

log_array "Search paths:" "${paths[@]}"

declare -a all_filters
get_all_lua_filters paths all_filters
log_array "Lua filters:" "${all_filters[@]}"

pandoc_filter_string=$(prefix_array "--lua-filter " "${all_filters[@]}")
inotify_filter_string=$(prefix_array "-f " "${all_filters[@]}")

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

pandoc_command="pandoc -f markdown+smart ${template_string} ${metadata_string} ${pandoc_filter_string} -o ${typst_file} ${md_file} &> \"${pandoc_log_file}\""
inotify_command="inotify-hookable -f ${md_file} ${inotify_template_string} ${inotify_metadata_string} ${inotify_filter_string} -c \"${pandoc_command}\""

log "Base file name: '${base_name}'"
log "Markdown file: '${md_file}'"
log "Typst file: '${typst_file}'"
log "Typst template file: '${typst_template}'"
log "Typst metadata file: '${typst_metadata}'"
log "Pandoc command: '${pandoc_command}'"
log "Inotify command: '${inotify_command}'"

pandoc_watch() {
    log "Running initial pandoc command..."
    eval ${pandoc_command} # initial run
    log "Running inotify..."
    eval ${inotify_command} # watching subsequent changes
}

typst_watch() {
    typst_command="typst watch ${typst_file}"
    log "Typst command: '${typst_command}'"
    log "Running typst ..."
    eval ${typst_command}
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