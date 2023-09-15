#!/bin/bash

this_dir="$(dirname "$(realpath "$0")")"
dot_systemd=$this_dir/config/systemd/user
user_systemd=$HOME/.config/systemd/user

daemons=$(command ls "$dot_systemd" | grep .service)
target=$(command ls "$dot_systemd" | grep .target)

mkdir -p "$user_systemd"

ln -sf "$dot_systemd/$target" "$user_systemd/$target"
for d in $daemons; do
	ln -sf "$dot_systemd/$d" "$user_systemd/$d"
	systemctl --user add-wants autostart.target "$d"
	systemctl --user enable "$d"
	systemctl --user start "$d"
	systemctl --user status "$d"
done
# systemctl --user set-default autostart.target
# systemctl --user daemon reload

# systemctl --user enable yandex-disk.service
# systemctl --user enable google-drive.service
# systemctl --user start yandex-disk.service
# systemctl --user start google-drive.service
# systemctl --user status yandex-disk.service
# systemctl --user status google-drive.service

# systemctl --user add-wants autostart.target yandex-disk.service
# systemctl --user add-wants autostart.target google-drive.service
# systemctl --user set-default autostart.target
