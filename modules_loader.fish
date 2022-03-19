#!/bin/fish

## Return code for __module_load and __module_unload functions
# 1 - No file/module passed
# 2 - File/module does not exist
# 3 - Module does not have one or more property set (__module_load only)
# 4 - Conflicts in modules_events or modules_functions variable (__module_load only)


rm -rf metadata
mkdir metadata
function __module_load_unload::sanitize # Sanitize function to cleanup vars
    # Sanitize
    set -ge __module_name
    set -ge __module_version
    set -ge __module_description
    set -ge __module_events
    set -ge __module_functions
end

function __module_load
    # 1. Sanitize env
    # 2. Make sure file exists
    # 3. Source the script
    # 4. Make sure all property are set
    # 5. Parse __module_events and __module_functions, handle conflicts
    # 6. Write module infos into a file in metadata/modulebasename.fish
    # 7. Append functions and events to a global variable if no conflict found
    __module_load_unload::sanitize
    pr_info "modules_loader" "__module_load: Loading module: $argv[1]"

    if test -z "$argv[1]"
        pr_error "modules_loader" "__module_unload: No filename given"
        return 1 # Don't waste time if no file is given
    end

    # Nor when the file does not exist
    if not test -f "$argv[1]"
        pr_error "modules_loader" "__module_load: File $argv[1] does not exist."
        return 2
    end

    # Source the given file
    source $argv[1]

    # All of the property are mandatory
    # throw if one of them are not set
    if not set -q __module_name
        or not set -q __module_version
        or not set -q __module_description
        or not set -q __module_events
        or not set -q __module_functions
        pr_warn "modules_loader" "__module_load: Module $argv[1] did not set one of the following property: __module_name, __module_version, __module_description, __module_events, __module_functions"
        pr_error "modules_loader" "__module_load: Cannot proceed loading module $argv[1] due to previous error."
        # Cleanup & abort
        __module_load_unload::sanitize
        return 3
    end

    ############ BEGIN module and events loading section #####################
    set -l fatal_exception_event
    set -l fatal_exception_function
    set -l abort false
    for ev in $__module_events
        for eve in $modules_events
            if test "$ev" = "$eve"
                pr_error "modules_loader" "__module_load: Fatal! A module tries to append an event which is already occupied by other module."
                set fatal_exception_event $ev
                set abort true
                break
            end
        end
        if test "$abort" = true
            break
        end
    end

    for fnt in $__module_functions
        if test "$abort" = true
            break
        end
        for fn in $modules_events
            if test "$ev" = "$eve"
                pr_error "modules_loader" "__module_load: Fatal! A module tries to append a function which is already occupied by other module."
                set fatal_exception_function $ev
                set abort true
                break
            end
        end
        if test "$abort" = true
            break
        end
    end
    ############ END module and events loading section #####################

    ############ BEGIN exception handling for module and events ###############
    if test "$abort" = true
        # Clean back up all set events except for
        # the same one, if we were to unset those,
        # then the module of which that belongs to
        # would break
        if test -n "$fatal_exception_event" # Remove all events set by the broken module
            for feve in $__module_events
                set -l index 1
                for ev in $modules_events
                    if test "$ev" = "$feve"
                        if test "$ev" != "$fatal_exception_event"
                            set -ge modules_events[$index]
                        end
                    end
                    set index (math $index + 1)
                end
            end
        end

        # The same for functions
        if test -n "$fatal_exception_function" # Remove all events set by the broken module
            for fnt in $__module_events
                set -l index 1
                for fn in $modules_events
                    if test "$ev" = "$feve"
                        if test "$ev" != "$fatal_exception_function"
                            set -ge modules_events[$index]
                        end
                    end
                    set index (math $index + 1)
                end
            end
        end
        return 4
    end

    ############ END exception handling for module and events ###############

    # Write module infos in a file
    set -l module_basename (basename $argv[1])
    echo "\
# Autogenerated by modules loader. Do NOT modify.
set -g __module_name \"$__module_name\"
set -g __module_version \"$__module_version\"
set -g __module_description \"$__module_description\"
set -g __module_events \"$__module_events\"
set -g __module_functions \"$__module_functions\"
" > metadata/$module_basename

    # Append events and functions to a global variables
    set -ga modules_events $__module_events
    set -ga modules_functions $__module_functions
    pr_info "modules_loader" "__module_load: Loaded module $argv[1]"
    pr_debug "modules_loader" "__module_load: Module $argv[1] name: $__module_name"
    pr_debug "modules_loader" "__module_load: Module $argv[1] version: $__module_version"
    pr_debug "modules_loader" "__module_load: Module $argv[1] description: $__module_description"
    pr_debug "modules_loader" "__module_load: Module $argv[1] events: $__module_events"
    pr_debug "modules_loader" "__module_load: Module $argv[1] functions: $__module_functions"
    __module_load_unload::sanitize
end

function __module_unload
    # 1. Verify that module exists
    # 2. Remove from global vars
    # 3. unset its functions and events
    # 4. Remove it's file from metadata dir
    pr_info "modules_loader" "Unloading module: $argv[1]"

    if test -z "$argv[1]"
        pr_error "modules_loader" "__module_unload: No filename given"
        return 1
    end

    set -l module_basename (basename $argv[1])
    if not test -f metadata/$module_basename
        pr_error "modules_loader" "__module_unload: Failed to unload module: $argv[1], module does not exist."
        return 2
    end

    __module_load_unload::sanitize
    source metadata/$module_basename

    # Erase functions
    pr_debug "modules_loader" "Erasing module $argv[1] functions"
    for fn in $__module_functions
        set -l index 1
        for fns in $modules_functions
            if test "$fns" = "$fn"
                pr_debug "modules_loader" "Erasing \$modules_functions at index $index"
                set -ge modules_functions[$index]
            end
            set index (math $index + 1)
        end
    end

    # Erase events
    pr_debug "modules_loader" "Erasing module $argv[1] events"
    for ev in $__module_events
        set -l index 1
        for evs in $modules_events
            if test "$evs" = "$ev"
                pr_debug "modules_loader" "Erasing \$modules_events at index $index"
                set -ge modules_events[$index]
            end
            set index (math $index + 1)
        end
    end

    rm -f metadata/$module_basename
    __module_load_unload::sanitize
end

function load_modules
    # Search for modules
    pr_info "modules_loader" "Searching for modules"
    set -l modules (find modules -type f -iname '*.fish')

    # Load them
    for module in $modules
        __module_load $module
    end
end

function run_modules
    for event in $modules_events
        emit $event
    end
end

load_modules
