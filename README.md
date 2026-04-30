# dotfiles — Hyprland

Rice pessoal baseado em Hyprland + Waybar + Matugen (Material You).

![screenshot](https://github.com/user-attachments/assets/cdfc60a8-9241-4633-bc23-8d80ebe9f862)

---

## Stack

| Componente | Programa |
|---|---|
| Compositor | Hyprland |
| Barra | Waybar |
| Launcher | Rofi |
| Terminal | Kitty |
| Notificações | Swaync |
| Lockscreen | Hyprlock |
| Idle | Hypridle |
| Logout | Wlogout |
| Wallpaper | Swww |
| Cores | Matugen (Material You) |
| Áudio visual | Cava |
| Shell | Zsh + Oh My Zsh |
| Fetch | Fastfetch |

---

## Instalação

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Opções do instalador

```
./install.sh              # instalação completa
./install.sh --deps-only  # só instala dependências
./install.sh --files-only # só copia os configs
./install.sh --dry-run    # mostra o que seria feito
```

---

## Estrutura

```
.
├── dots/                        # configs que vão para ~/
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland.conf    # config principal
│   │   │   ├── colors.conf      # gerado pelo matugen (não editar)
│   │   │   ├── configs/         # defaults (keybinds, look, input…)
│   │   │   ├── custom/          # ← EDITA AQUI as tuas customizações
│   │   │   │   ├── env.conf
│   │   │   │   ├── execs.conf
│   │   │   │   ├── keybinds.conf
│   │   │   │   └── rules.conf
│   │   │   ├── scripts/         # scripts bash
│   │   │   ├── hypridle.conf
│   │   │   └── hyprlock.conf
│   │   ├── waybar/              # configs e estilos da barra
│   │   ├── rofi/                # launcher
│   │   ├── kitty/               # terminal
│   │   ├── matugen/             # templates de cores
│   │   ├── swaync/              # notificações
│   │   ├── wlogout/             # menu de logout
│   │   ├── cava/                # visualizador de áudio
│   │   └── fastfetch/           # system info
│   ├── wallpapers/              # wallpapers incluídos
│   └── .zshrc
├── install.sh                   # script de instalação
└── README.md
```

---

## Customização

Edita os ficheiros em `~/.config/hypr/custom/` — são carregados por cima dos defaults e não são sobrescritos em updates:

- `env.conf` — variáveis de ambiente extras (ex: `MOZ_ENABLE_WAYLAND`)
- `execs.conf` — programas extras no autostart
- `keybinds.conf` — atalhos extras
- `rules.conf` — window rules extras

Para o monitor, edita `~/.config/hypr/hyprland.conf`:
```ini
monitor = eDP-1, 1920x1080@60, 0x0, 1
# Usa `hyprctl monitors` para ver o nome do teu monitor
```

---

## Keybinds principais

| Atalho | Ação |
|---|---|
| `Super + Enter` | Terminal |
| `Super + D` | Launcher (Rofi) |
| `Super + W` | Wallpaper picker + tema de cores |
| `Super + L` | Lockscreen |
| `Super + Q` | Fechar janela |
| `Super + Shift + S` | Screenshot (área) |
| `Super + Shift + F` | Fullscreen |
| `Super + Space` | Toggle float |
| `Super + Ctrl + B` | Estilos do Waybar |
| `Super + Alt + B` | Layouts do Waybar |
| `Super + H` | Esconder/mostrar Waybar |
| `Super + 1-0` | Mudar workspace |
| `Super + Shift + 1-0` | Mover janela para workspace |

---

## Sistema de cores (Matugen)

Ao escolher um wallpaper com `Super+W`, o Matugen gera automaticamente um tema Material You e aplica em:
- Hyprland (bordas)
- Waybar
- Kitty
- Rofi
- Cava
- GTK 3/4
- Spotify (Spicetify)
- Discord (Vesktop)

---

## Créditos

- [JaKooLit](https://github.com/JaKooLit) — scripts e configs do Waybar
- [Matugen](https://github.com/InioX/matugen) — gerador de cores
