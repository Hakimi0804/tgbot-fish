#!/bin/fish

set -g __module_name "Bot log access module (log_dump.fish)"
set -g __module_description "Not relevant to other than bot owner."
set -g __module_version 1
set -g __module_functions rar
set -g __module_help_message "Available commands:
`.unrar` \<Reply to a message\>"

function rar --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.unrar'
            # Make sure we're replying to a file
            if test "$ret_replied_file_id" = null
                tg --replymsg $ret_chat_id $ret_msg_id "Reply to a file please"
                return
            end

            tg --replymsg $ret_chat_id $ret_msg_id Preparing
            set -l file_path (
            curl -s $API/getFile -d chat_id=$ret_chat_id -d file_id=$ret_replied_file_id |
                jq -r .result.file_path
        )
            set file_path https://api.telegram.org/file/bot$TOKEN/$file_path

            tg --editmsg $ret_chat_id $sent_msg_id Downloading

            set -l start_time (date +%s.%N)
            set -l tmpdir (mktemp -d)
            set -l origpath $PWD
            set -l randfname file-(random).rar

            aria2c $file_path -o $tmpdir/$randfname
            or __rar_err_handler && return

            tg --editmsg $ret_chat_id $sent_msg_id "Extracting"
            cd $tmpdir
            unrar e (basename $randfname)

            rm -f $randfname
            tg --editmsg $ret_chat_id $sent_msg_id "Uploading"
            __rar_upload (find -type f)
            __rar_cleanup

            cd $origpath
    end
end

function __rar_err_handler -S
    tg --editmsg $ret_chat_id $sent_msg_id "Failed to extract archive"
    __rar_cleanup
end

function __rar_cleanup -S
    rm -rf $tmpdir
end

function __rar_upload
    for file in $argv
        curl -s $API/sendDocument -F chat_id=$ret_chat_id -F document=@$file &

        while test (jobs | count) -gt 5
            :
        end
    end
end