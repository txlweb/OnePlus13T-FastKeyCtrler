#!/bin/bash
[ "$(settings get global zen_mode)" = "0" ] && cmd notification set_dnd on || cmd notification set_dnd off
