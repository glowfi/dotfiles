# qs-mango

gruvbox status bar + popups for MangoWM, built on quickshell.
everything renders in-shell; CLIs run silently as backends.

## features

    tags            per-monitor, urgent highlight
    layout          click picker / right cycle / middle float
    media           MPRIS popup: cover art, seek, transport
    tray            SNI, in-shell menus, passive items hidden
    sysmon          cpu ram disk net; btop on click
    gpu             per-card busy + vram, multi-gpu switch
    wifi            scan, connect, inline password
    bluetooth       pair, connect, forget, battery
    audio           in/out sliders + device pickers
    display         brightness, night light, font size,
                    per-monitor scale/resolution/rotation/
                    position/on-off (persisted)
    battery         stats + power profiles
    notifications   daemon, toasts, history, dnd
    clipboard       cliphist, fuzzy search
    wallpaper       thumbnail grid -> awww (grow transition)
    calendar        browsable month view
    osd             volume/brightness pill

## deps

    quickshell mango ttf-nerd-fonts-symbols papirus-icon-theme
    networkmanager cliphist wl-clipboard wlsunset brightnessctl
    power-profiles-daemon wlr-randr pciutils awww kitty btop

    systemctl enable --now power-profiles-daemon

## install

    cp -r shell.qml Bar.qml Services Widgets modules ~/.config/quickshell/

~/.config/mango/config.conf:

    exec-once=quickshell
    exec-once=wl-paste --watch cliphist store
    exec-once=awww-daemon

kill any other notification daemon (mako/dunst/swaync) and wallpaper
daemon (swaybg/swww); this shell owns both roles.

media keys (optional):

    bind=NONE,XF86AudioRaiseVolume,spawn,qs ipc call osd volumeUp
    bind=NONE,XF86AudioLowerVolume,spawn,qs ipc call osd volumeDown
    bind=NONE,XF86AudioMute,spawn,qs ipc call osd mute
    bind=NONE,XF86MonBrightnessUp,spawn,qs ipc call osd brightnessUp
    bind=NONE,XF86MonBrightnessDown,spawn,qs ipc call osd brightnessDown

## layout

    shell.qml       bars + toasts + osd
    Bar.qml         assembly: widget row, popup manager
    Services/       one singleton per backend
    Widgets/        reusable primitives
    modules/        one folder per feature (pill + popup)
    modules/_template/   copy to add a feature

rules: state and CLIs only in Services; colors/sizes only via Theme;
wiring only in Bar.qml.

## config

    font/colors     Services/Theme.qml
    wallpaper dir   Services/Wallpaper.qml  (default ~/wall)
    tray blocklist  modules/tray/Tray.qml

state files: ~/.config/mango/{monitors.json,monitors.sh,shell-ui.json}

## notes

    pairing PIN devices needs bluetoothctl once
    verify mango IPC: mmsg get all-monitors
