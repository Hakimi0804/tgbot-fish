#!/bin/fish

set -ga modules_events "testing_group_rm6785_ch"
function realme_rm --on-event 'testing_group_rm6785_ch'
    switch $ret_lowered_msg_text
        case '.sticker*'
            for user in $fwd_auth_user
                if test "$msgger" = "$user"
                    if string match -qe -- "$ret_chat_id" "$fwd_approved_chat_id"
                        tg --replymsg "$ret_chat_id" "$ret_msg_id" "Hold on..."
                        tg --sendsticker "$fwd_to" "$rm6785_update_sticker"
                        tg --editmsg "$ret_chat_id" "$sent_msg_id" "Sticker sent"
                    else
                        tg --replymsg "$ret_chat_id" "$ret_msg_id" "You are not allowed to use this command outside testing group"
                    end
                    return
                end
            end
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to use this command"
        case '.post*'
            for user in $fwd_auth_user
                if test "$msgger" = "$user"
                    if string match -qe -- "$ret_chat_id" "$fwd_approved_chat_id"
                        if test "$ret_replied_msg_id" = null
                            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message please"
                        else
                            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Hold on..."
                            tg --cpmsg "$ret_chat_id" "$fwd_to" "$ret_replied_msg_id"
                            tg --editmsg "$ret_chat_id" "$sent_msg_id" "Posted"
                        end
                    else
                    end
                    return
                end
            end
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to do this bsdk"
        case '.auth*'
            set -l authorized false
            for user in $bot_owner_id $fwd_auth_user
                if test "$msgger" = "$user"
                    set authorized true
                    break
                end
            end
            if test $authorized = true
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Authorizing that user"
                if test "$ret_replied_msg_id" = null
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "Reply to a user plox"
                else
                    echo "$ret_replied_msgger_id" >> modules/assets/rm6785_auth_user
                    set -g fwd_auth_user $bot_owner_id (command cat modules/assets/rm6785_auth_user)
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "That user is now authorized, enjoy"
                end
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to do this bsdk"
            end
    end
end
