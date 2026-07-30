#!/usr/bin/env python3
"""
Generate the rice colour set from a wallpaper and fan it out to the consumers.

Uses matugen's native Material Design 3 colour extraction to derive the full
palette from a wallpaper image in a single subprocess call. matugen performs its
own image analysis in Rust (using the HCT perceptual colour space from Material
You), so the old ImageMagick histogram pipeline is unnecessary and has been
removed.

The Material You palette provides perceptually uniform surface tiers, accent
ramps, and contrast-safe text tones out of the box. This script maps them
directly to the pill JSON keys that Dyn.qml and Theme.qml consume, and derives
the remaining custom text tokens (cream, bright, subtle, dim, faint, icon_dim,
tick_rest) by interpolating between the Material You on_surface and
outline_variant tones. The base16 terminal palette and the grey ramp adjustment
are still post-processed from matugen's wal backend.

Output files:
  ~/.cache/ricelin/colors.json     – pill JSON (Quickshell Dyn.qml)
  ~/.cache/ricelin/hypr-colors.lua – Hyprland border colours
  ~/.cache/ricelin/ghostty-colors  – Ghostty terminal palette
  ~/.config/gtk-{3,4}.0/colors.css – GTK accent/surface overrides
  ~/.config/fastfetch/config.jsonc – fastfetch logo/key colours
"""

import colorsys
import json
import subprocess
import sys
import time
from pathlib import Path

CACHE = Path.home() / ".cache" / "ricelin"


def hex_to_hls(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)


def hls_to_hex(h, l, s):
    r, g, b = colorsys.hls_to_rgb(h, max(0.0, min(1.0, l)), max(0.0, min(1.0, s)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def blend(hex_a, hex_b, t):
    """Linearly interpolate between two hex colours in HLS space."""
    ha, la, sa = hex_to_hls(hex_a)
    hb, lb, sb = hex_to_hls(hex_b)
    return hls_to_hex(
        ha + (hb - ha) * t,
        la + (lb - la) * t,
        sa + (sb - sa) * t,
    )


def tint(hue, sat, light):
    """Build a hex colour from HSL values (kept for --hue manual mode)."""
    r, g, b = colorsys.hls_to_rgb(
        hue % 1.0, max(0.0, min(1.0, light)), max(0.0, min(1.0, sat))
    )
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def run_matugen_image(wallpaper):
    """Run matugen with native image analysis — single subprocess, ~430ms."""
    out = subprocess.run(
        [
            "matugen",
            "image",
            wallpaper,
            "-m",
            "dark",
            "-t",
            "scheme-vibrant",
            "--contrast",
            "0.25",
            "-j",
            "hex",
            "-b",
            "wal",
            "--old-json-output",
            "--source-color-index",
            "0",
            "-r",
            "lanczos3",
            "--prefer",
            "saturation",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(out.stdout)


def run_matugen_hex(source_hex):
    """Run matugen from a source hex colour (--hue manual mode)."""
    out = subprocess.run(
        [
            "matugen",
            "color",
            "hex",
            source_hex,
            "-m",
            "dark",
            "-t",
            "scheme-vibrant",
            "--contrast",
            "0.25",
            "-j",
            "hex",
            "-b",
            "wal",
            "--old-json-output",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(out.stdout)


def build_pill(colors):
    """Map Material You tokens to the pill JSON consumed by Dyn.qml.

    Surface tiers and accent tokens map directly. The 7-step text ramp
    (cream → faint) is interpolated from on_surface (brightest readable text)
    down through on_surface_variant and outline_variant (faintest).
    """
    d = lambda key: colors[key]["dark"]

    # Surface containers — direct from Material You
    pill = {
        "surface": d("surface"),
        "surface_container_low": d("surface_container_low"),
        "surface_container": d("surface_container"),
        "surface_container_high": d("surface_container_high"),
        "surface_container_highest": d("surface_container_highest"),
        "outline_variant": d("outline_variant"),
    }

    # Accent tokens
    pill["primary"] = d("primary")
    pill["primary_container"] = d("primary_container")
    pill["outline"] = d("outline")

    # on_primary_container: matugen can return pure white (#ffffff) which is
    # too harsh for the pill; clamp it to a softer tint derived from on_surface.
    opc = d("on_primary_container")
    if hex_to_hls(opc)[1] > 0.92:
        opc = blend(d("on_surface"), "#ffffff", 0.4)
    pill["on_primary_container"] = opc

    # 7-step text ramp — interpolate from bright through subtle to faint
    on_surf = d("on_surface")
    on_surf_var = d("on_surface_variant")
    outline_var = d("outline_variant")

    # bright (nearly white) → cream (soft white) → subtle → dim → faint
    pill["bright"] = blend(on_surf, "#ffffff", 0.35)
    pill["cream"] = blend(on_surf, "#ffffff", 0.15)
    pill["subtle"] = on_surf_var
    pill["dim"] = blend(on_surf_var, outline_var, 0.45)
    pill["faint"] = outline_var
    pill["icon_dim"] = blend(on_surf, on_surf_var, 0.55)
    pill["tick_rest"] = blend(on_surf, on_surf_var, 0.65)

    return pill


def adjust_gray_ramp(b, on_bg):
    """Post-process the base16 grey ramp for terminal readability.

    Spreads the grey ramp (base00–base07) evenly between the background and
    foreground lightness so comments (base03) and default text (base05) are
    clearly readable. Accent colours (base08–base0f) are lifted to a minimum
    lightness of 0.50 for dark-on-dark legibility.
    """
    h_bg, l_bg, s_bg = hex_to_hls(b["base00"])
    h_fg, l_fg, s_fg = hex_to_hls(on_bg)

    target_lights = {
        "base00": l_bg,
        "base01": l_bg + (l_fg - l_bg) * 0.15,
        "base02": l_bg + (l_fg - l_bg) * 0.30,
        "base03": l_bg + (l_fg - l_bg) * 0.50,
        "base04": l_bg + (l_fg - l_bg) * 0.75,
        "base05": l_fg,
        "base06": l_fg + (1.0 - l_fg) * 0.50,
        "base07": l_fg + (1.0 - l_fg) * 0.90,
    }

    for key, l_target in target_lights.items():
        h, l, s = hex_to_hls(b[key])
        s_target = max(s, 0.12)
        b[key] = hls_to_hex(h, l_target, s_target)

    for key in [
        "base08",
        "base09",
        "base0a",
        "base0b",
        "base0c",
        "base0d",
        "base0e",
        "base0f",
    ]:
        h, l, s = hex_to_hls(b[key])
        s_target = max(s, 0.65)
        l_target = max(l, 0.55)
        b[key] = hls_to_hex(h, l_target, s_target)



def render_fastfetch(pill):
    """Recolour the fastfetch readout from the pill palette.

    fastfetch has no daemon, so writing the rendered config is enough — the
    next run picks it up. The accent drives the keys and the torii, the surface
    ramp the lantern body, and a dim text tone the section rules.
    """
    ff = Path.home() / ".config" / "fastfetch"
    tmpl = ff / "config.jsonc.in"
    if not tmpl.is_file():
        print("wallcolors: config.jsonc.in missing in ~/.config/fastfetch, skipping "
              "fastfetch recolour (apply the Ricelin update or re-run the installer)",
              file=sys.stderr)
        return
    seq = lambda h: "%d;%d;%d" % tuple(int(h[i : i + 2], 16) for i in (1, 3, 5))
    repl = {
        "__LANTERN__": str(ff / "lantern.txt"),
        "__KEYS__": seq(pill["primary"]),
        "__SEP__": seq(pill["dim"]),
        "__LOGO1__": seq(pill["primary"]),
        "__LOGO2__": seq(pill["on_primary_container"]),
        "__LOGO3__": seq(pill["surface_container"]),
        "__LOGO4__": seq(pill["surface_container_high"]),
        "__LOGO5__": seq(pill["subtle"]),
        "__LOGO6__": seq(pill["outline"]),
        "__LOGO7__": seq(pill["bright"]),
    }
    out = tmpl.read_text()
    for key, val in repl.items():
        out = out.replace(key, val)
    (ff / "config.jsonc").write_text(out)


def write_hypr_colors(pill):
    """Write Hyprland border colour cache."""
    (CACHE / "hypr-colors.lua").write_text(
        'return {\n    c1 = "%s",\n    c2 = "%s",\n}\n'
        % (pill["surface_container_highest"], pill["outline_variant"])
    )


def write_ghostty_colors(pill, b, on_bg):
    """Write Ghostty terminal colour override file."""
    lines = [
        f"background = {pill['surface']}",
        f"foreground = {on_bg}",
        f"cursor-color = {pill['primary']}",
        f"selection-background = {pill['surface_container_highest']}",
        f"selection-foreground = {on_bg}",
    ]
    # Correct base16 mapping to standard 16 ANSI colors
    mapping = {
        0: "base00",  # Black
        1: "base08",  # Red
        2: "base0b",  # Green
        3: "base0a",  # Yellow
        4: "base0d",  # Blue
        5: "base0e",  # Magenta
        6: "base0c",  # Cyan
        7: "base05",  # White
        8: "base03",  # Bright Black (Gray)
        9: "base08",  # Bright Red
        10: "base0b", # Bright Green
        11: "base0a", # Bright Yellow
        12: "base0d", # Bright Blue
        13: "base0e", # Bright Magenta
        14: "base0c", # Bright Cyan
        15: "base07", # Bright White
    }
    for ansi_idx, base_key in mapping.items():
        lines.append(f"palette = {ansi_idx}={b[base_key]}")
    (CACHE / "ghostty-colors").write_text("\n".join(lines) + "\n")


def write_btop_colors(pill, b, on_bg):
    """Write btop terminal theme override file."""
    lines = [
        "# Theme: ricelin generated",
        "# Generated dynamically by wallcolors.py",
        "",
        f"theme[main_bg]=\"{pill['surface']}\"",
        f"theme[main_fg]=\"{on_bg}\"",
        f"theme[title]=\"{on_bg}\"",
        f"theme[hi_fg]=\"{pill['primary']}\"",
        f"theme[selected_bg]=\"{b['base02']}\"",
        f"theme[selected_fg]=\"{on_bg}\"",
        f"theme[inactive_fg]=\"{b['base03']}\"",
        f"theme[proc_misc]=\"{pill['primary']}\"",
        f"theme[cpu_box]=\"{b['base03']}\"",
        f"theme[mem_box]=\"{b['base03']}\"",
        f"theme[net_box]=\"{b['base03']}\"",
        f"theme[proc_box]=\"{b['base03']}\"",
        f"theme[div_line]=\"{b['base03']}\"",
        f"theme[temp_start]=\"{b['base0b']}\"",
        f"theme[temp_mid]=\"{b['base0a']}\"",
        f"theme[temp_end]=\"{b['base08']}\"",
        f"theme[cpu_start]=\"{b['base0b']}\"",
        f"theme[cpu_mid]=\"{b['base0a']}\"",
        f"theme[cpu_end]=\"{b['base08']}\"",
        f"theme[free_start]=\"{b['base0b']}\"",
        f"theme[free_mid]=\"{b['base0a']}\"",
        f"theme[free_end]=\"{b['base08']}\"",
        f"theme[cached_start]=\"{b['base0b']}\"",
        f"theme[cached_mid]=\"{b['base0a']}\"",
        f"theme[cached_end]=\"{b['base08']}\"",
        f"theme[available_start]=\"{b['base0b']}\"",
        f"theme[available_mid]=\"{b['base0a']}\"",
        f"theme[available_end]=\"{b['base08']}\"",
        f"theme[used_start]=\"{b['base0b']}\"",
        f"theme[used_mid]=\"{b['base0a']}\"",
        f"theme[used_end]=\"{b['base08']}\"",
        f"theme[download_start]=\"{b['base0b']}\"",
        f"theme[download_mid]=\"{b['base0a']}\"",
        f"theme[download_end]=\"{b['base08']}\"",
        f"theme[upload_start]=\"{b['base0b']}\"",
        f"theme[upload_mid]=\"{b['base0a']}\"",
        f"theme[upload_end]=\"{b['base08']}\"",
    ]
    btop_dir = Path.home() / ".config" / "btop" / "themes"
    btop_dir.mkdir(parents=True, exist_ok=True)
    (btop_dir / "ricelin.theme").write_text("\n".join(lines) + "\n")


def write_gtk_colors(pill):
    """Write GTK 3/4 accent and surface CSS overrides."""
    gtk_colors = f"""@define-color theme_bg_color {pill["surface"]};
@define-color theme_fg_color {pill["bright"]};
@define-color theme_base_color {pill["surface_container"]};
@define-color theme_text_color {pill["bright"]};
@define-color theme_selected_bg_color {pill["primary"]};
@define-color theme_selected_fg_color {pill["surface"]};
@define-color theme_view_bg_color {pill["surface_container"]};
@define-color theme_view_fg_color {pill["bright"]};

@define-color window_bg_color {pill["surface"]};
@define-color window_fg_color {pill["bright"]};
@define-color view_bg_color {pill["surface_container"]};
@define-color view_fg_color {pill["bright"]};
@define-color headerbar_bg_color {pill["surface"]};
@define-color headerbar_fg_color {pill["bright"]};
@define-color theme_unfocused_bg_color {pill["surface"]};
@define-color theme_unfocused_fg_color {pill["bright"]};
@define-color theme_unfocused_base_color {pill["surface_container"]};
@define-color theme_unfocused_text_color {pill["bright"]};
@define-color theme_unfocused_selected_bg_color {pill["primary"]};
@define-color theme_unfocused_selected_fg_color {pill["surface"]};

@define-color headerbar_border_color {pill["outline"]};
@define-color headerbar_backdrop_color {pill["surface"]};
@define-color headerbar_shade_color rgba(0, 0, 0, 0.36);
@define-color popover_bg_color {pill["surface"]};
@define-color popover_fg_color {pill["bright"]};
@define-color card_bg_color {pill["surface_container"]};
@define-color card_fg_color {pill["bright"]};
@define-color dialog_bg_color {pill["surface"]};
@define-color dialog_fg_color {pill["bright"]};
@define-color sidebar_bg_color {pill["surface"]};
@define-color sidebar_fg_color {pill["bright"]};

@define-color accent_color {pill["primary"]};
@define-color accent_bg_color {pill["primary"]};
@define-color accent_fg_color {pill["surface"]};

window, dialog, popover, .background, * {{
  --accent-bg-color: {pill["primary"]};
  --accent-fg-color: {pill["surface"]};
  --accent-color: {pill["primary"]};
  --window-bg-color: {pill["surface"]};
  --window-fg-color: {pill["bright"]};
  --view-bg-color: {pill["surface_container"]};
  --view-fg-color: {pill["bright"]};
  --headerbar-bg-color: {pill["surface"]};
  --headerbar-fg-color: {pill["bright"]};
  --popover-bg-color: {pill["surface"]};
  --popover-fg-color: {pill["bright"]};
  --card-bg-color: {pill["surface_container"]};
  --card-fg-color: {pill["bright"]};
  --dialog-bg-color: {pill["surface"]};
  --dialog-fg-color: {pill["bright"]};
  --sidebar-bg-color: {pill["surface"]};
  --sidebar-fg-color: {pill["bright"]};

  --window-backdrop-color: {pill["surface"]};
  --window-backdrop-fg-color: {pill["bright"]};
  --view-backdrop-color: {pill["surface_container"]};
  --view-backdrop-fg-color: {pill["bright"]};
  --headerbar-backdrop-color: {pill["surface"]};
  --headerbar-backdrop-fg-color: {pill["bright"]};
  --popover-backdrop-color: {pill["surface"]};
  --popover-backdrop-fg-color: {pill["bright"]};
  --card-backdrop-color: {pill["surface_container"]};
  --card-backdrop-fg-color: {pill["bright"]};
  --dialog-backdrop-color: {pill["surface"]};
  --dialog-backdrop-fg-color: {pill["bright"]};
  --sidebar-backdrop-color: {pill["surface"]};
  --sidebar-backdrop-fg-color: {pill["bright"]};
}}

/* Force backdrop states to match active states — prevents white headers
   and dimmed text when a window loses focus. These direct property overrides
   beat the theme's own :backdrop rules because colors.css is imported last. */
.background:backdrop,
window:backdrop,
headerbar:backdrop,
headerbar:backdrop>windowhandle {{
  background-color: {pill["surface"]};
  color: {pill["bright"]};
  transition: none;
}}

headerbar:backdrop>windowhandle {{
  filter: none;
}}

.titlebar:backdrop,
.titlebar:not(headerbar):backdrop {{
  background-color: {pill["surface"]};
  color: {pill["bright"]};
}}

/* Direct overrides to bypass theme's hardcoded colors and enforce wallpaper colors */
.background,
.background:backdrop,
window,
window:backdrop,
dialog,
dialog:backdrop,
popover,
popover:backdrop,
.popover,
.popover:backdrop,
headerbar,
headerbar:backdrop,
.titlebar,
.titlebar:backdrop,
.titlebar:not(headerbar),
.titlebar:not(headerbar):backdrop {{
  background-color: {pill["surface"]};
  color: {pill["bright"]};
  background-image: none;
  box-shadow: none;
  border: none;
}}

headerbar *,
headerbar *:backdrop,
.titlebar *,
.titlebar *:backdrop {{
  color: {pill["bright"]};
}}

/* Base containers, views, cards, scrolled windows, and text inputs */
.view,
.view:backdrop,
textview,
textview:backdrop,
text,
text:backdrop,
entry,
entry:backdrop,
list,
list:backdrop,
row,
row:backdrop,
.card,
.card:backdrop,
scrolledwindow,
scrolledwindow:backdrop {{
  background-color: {pill["surface_container"]};
  color: {pill["bright"]};
}}

/* Buttons style overrides */
button,
button:backdrop,
button:focus,
button:focus:backdrop,
button:focus-visible,
button:focus-visible:backdrop {{
  background-color: {pill["surface_container"]};
  color: {pill["bright"]};
  border: none;
  box-shadow: none;
  outline: none;
  background-image: none;
}}

button:hover,
button:hover:backdrop {{
  background-color: {pill["surface_container_high"]};
}}

button:active,
button:active:backdrop,
button:checked,
button:checked:backdrop {{
  background-color: {pill["surface_container_highest"]};
}}

/* Suggested actions and featured buttons (like equals button in gnome-calculator) */
button.suggested-action,
button.suggested-action:backdrop,
button.suggested-action:focus,
button.suggested-action:focus:backdrop,
button.suggested-action:focus-visible,
button.suggested-action:focus-visible:backdrop,
.suggested-action,
.suggested-action:backdrop,
.suggested-action:focus,
.suggested-action:focus-visible,
.featured,
.featured:backdrop,
.featured:focus,
.featured:focus-visible,
button.suggested-action *,
button.suggested-action *:backdrop,
.suggested-action *,
.suggested-action *:backdrop,
.featured *,
.featured *:backdrop {{
  background-color: {pill["primary"]};
  color: {pill["surface"]};
  background-image: none;
  border: none;
  box-shadow: none;
  outline: none;
}}

button.suggested-action:hover,
button.suggested-action:hover:backdrop,
.suggested-action:hover,
.suggested-action:hover:backdrop,
.featured:hover,
.featured:hover:backdrop {{
  background-color: {pill["primary_container"]};
}}

button.suggested-action:active,
button.suggested-action:active:backdrop,
button.suggested-action:checked,
button.suggested-action:checked:backdrop,
.suggested-action:active,
.suggested-action:active:backdrop,
.suggested-action:checked,
.suggested-action:checked:backdrop,
.featured:active,
.featured:active:backdrop,
.featured:checked,
.featured:checked:backdrop {{
  background-color: {pill["primary_container"]};
  color: {pill["surface"]};
  background-image: none;
  border: none;
  box-shadow: none;
  outline: none;
}}
"""
    home_dir = Path.home()
    for ver in ["gtk-3.0", "gtk-4.0"]:
        gtk_dir = home_dir / ".config" / ver
        gtk_dir.mkdir(parents=True, exist_ok=True)
        (gtk_dir / "colors.css").write_text(gtk_colors)


def write_nvim_colors(pill, b, on_bg):
    """Write Neovim colorscheme lua file."""
    lines = [
        "return {",
        f"    base00 = '{b['base00']}',",
        f"    base01 = '{b['base01']}',",
        f"    base02 = '{b['base02']}',",
        f"    base03 = '{b['base03']}',",
        f"    base04 = '{b['base04']}',",
        f"    base05 = '{b['base05']}',",
        f"    base06 = '{b['base06']}',",
        f"    base07 = '{b['base07']}',",
        f"    base08 = '{b['base08']}',",
        f"    base09 = '{b['base09']}',",
        f"    base0a = '{b['base0a']}',",
        f"    base0b = '{b['base0b']}',",
        f"    base0c = '{b['base0c']}',",
        f"    base0d = '{b['base0d']}',",
        f"    base0e = '{b['base0e']}',",
        f"    base0f = '{b['base0f']}',",
        f"    primary = '{pill['primary']}',",
        f"    subtle = '{pill['subtle']}',",
        f"    bright = '{pill['bright']}',",
        "}"
    ]
    (CACHE / "nvim-colors.lua").write_text("\n".join(lines) + "\n")


def reload_gtk_theme():
    """Toggle GTK theme and color-scheme to force running apps to reload CSS.

    GTK3 apps watch the 'gtk-theme' gsetting, while GTK4/libadwaita apps
    watch 'color-scheme'. Toggling both ensures all GTK apps re-read their
    CSS providers and pick up the freshly written colors.css.
    """
    try:
        # --- GTK3: toggle gtk-theme ---
        res = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"],
            capture_output=True, text=True, check=True,
        )
        current_theme = res.stdout.strip().strip("'").strip('"')

        # --- GTK4: toggle color-scheme ---
        res2 = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
            capture_output=True, text=True, check=True,
        )
        current_scheme = res2.stdout.strip().strip("'").strip('"')

        # Flip to a different value briefly
        temp_theme = "Adwaita" if current_theme != "Adwaita" else "HighContrast"
        temp_scheme = "default" if current_scheme != "default" else "prefer-light"

        subprocess.run(
            ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", temp_theme],
            check=True,
        )
        subprocess.run(
            ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", temp_scheme],
            check=True,
        )

        # Toggle xsettingsd if running
        xsettingsd_conf = Path.home() / ".config" / "xsettingsd" / "xsettingsd.conf"
        xsettingsd_content = None
        if xsettingsd_conf.exists():
            try:
                xsettingsd_content = xsettingsd_conf.read_text()
                temp_content = xsettingsd_content.replace(
                    f'Net/ThemeName "{current_theme}"',
                    f'Net/ThemeName "{temp_theme}"'
                )
                xsettingsd_conf.write_text(temp_content)
                subprocess.run(["killall", "-HUP", "xsettingsd"], stderr=subprocess.DEVNULL)
            except Exception:
                pass

        # Let D-Bus propagate the change so apps actually re-read their CSS
        time.sleep(0.3)

        # Restore originals
        subprocess.run(
            ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", current_theme],
            check=True,
        )
        subprocess.run(
            ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", current_scheme],
            check=True,
        )

        # Restore xsettingsd original configuration
        if xsettingsd_conf.exists() and xsettingsd_content is not None:
            try:
                xsettingsd_conf.write_text(xsettingsd_content)
                subprocess.run(["killall", "-HUP", "xsettingsd"], stderr=subprocess.DEVNULL)
            except Exception:
                pass
    except Exception:
        pass


def main():
    if len(sys.argv) < 2:
        return 1

    if sys.argv[1] == "--hue":
        # Manual hue mode: build a source colour and run matugen color hex
        hue = (float(sys.argv[2]) % 360) / 360.0
        mode = sys.argv[3] if len(sys.argv) > 3 else "dark"
        sat = float(sys.argv[4]) if len(sys.argv) > 4 else 0.5
        sat = max(0.0, min(1.0, sat))
        light = 0.45 if mode == "dark" else 0.55
        source_hex = tint(hue, sat, light)
        try:
            m_res = run_matugen_hex(source_hex)
        except (OSError, ValueError, subprocess.SubprocessError):
            return 0
    else:
        # Image mode: let matugen extract the source colour natively
        wallpaper = sys.argv[1]
        if not Path(wallpaper).is_file():
            return 0
        try:
            m_res = run_matugen_image(wallpaper)
        except (OSError, ValueError, subprocess.SubprocessError):
            return 0

    CACHE.mkdir(parents=True, exist_ok=True)

    colors = m_res.get("colors", {})
    if not colors:
        return 0

    # Build and write the pill JSON
    pill = build_pill(colors)
    (CACHE / "colors.json").write_text(json.dumps(pill, indent=2) + "\n")

    # Render fastfetch config
    render_fastfetch(pill)

    # Process base16 terminal palette
    try:
        b = {k: v["dark"] for k, v in m_res["base16"].items()}
        # Check if the generated base16 is invalid/fallback (e.g. base0b or base0d is black or default)
        is_invalid = b.get("base00") == "#000000" and b.get("base05") == "#000000" or b.get("base0b") == "#000000"
        if is_invalid:
            # Fallback mapping from Material Design 3 colors, same as module.nix
            d = lambda key, fallback: colors.get(key, {}).get("dark", fallback)
            b = {
                "base00": d("surface", "#111318"),
                "base01": d("surface_container_low", "#1a1b20"),
                "base02": d("surface_container", "#1e1f25"),
                "base03": d("outline", "#8e9099"),
                "base04": d("on_surface_variant", "#c4c6d0"),
                "base05": d("on_surface", "#e2e2e9"),
                "base06": d("surface_bright", "#37393e"),
                "base07": d("inverse_on_surface", "#2f3036"),
                "base08": d("error", "#ffb4ab"),
                "base09": d("tertiary", "#debcdf"),
                "base0a": d("secondary", "#bfc6dc"),
                "base0b": d("primary", "#adc6ff"),
                "base0c": d("tertiary", "#debcdf"),
                "base0d": d("primary", "#adc6ff"),
                "base0e": d("tertiary", "#debcdf"),
                "base0f": d("outline", "#8e9099"),
            }
        on_bg = colors["on_background"]["dark"]
        adjust_gray_ramp(b, on_bg)
    except KeyError:
        return 0

    # Write all output files
    write_hypr_colors(pill)
    write_ghostty_colors(pill, b, on_bg)
    write_btop_colors(pill, b, on_bg)
    write_gtk_colors(pill)
    write_nvim_colors(pill, b, on_bg)
    reload_gtk_theme()

    return 0


if __name__ == "__main__":
    sys.exit(main())
