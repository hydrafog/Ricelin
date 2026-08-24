local home = os.getenv("HOME")
local ok, wc = pcall(dofile, home .. "/.cache/ricelin/hypr-colors.lua")
if not ok then wc = nil end

local function border(hex, fallback)
    if type(hex) ~= "string" then hex = fallback end
    return "rgba(" .. hex:gsub("#", "") .. "33)"
end

local active   = border(wc and wc.c2 or wc and wc.inactive or wc and wc.active, "ffffff18")
local inactive = "rgba(00000000)"

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
    general = {
        gaps_in     = 8,
        gaps_out    = 16,
        border_size = 1,
        layout      = "dwindle",
        resize_on_border = true,
        ["col.active_border"]   = active,
        ["col.inactive_border"] = inactive,
    },
    decoration = {
        rounding         = 20,
        rounding_power   = 2.0,
        active_opacity   = 1.00,
        inactive_opacity = 1.00,
        dim_inactive     = true,
        dim_strength     = 0.12,
        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 3,
            color        = "rgba(0000004d)",
            color_inactive = "rgba(00000028)",
            offset       = "0, 6",
            scale        = 1.0,
        },
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            vibrancy          = 0.25,
            noise             = 0.01,
            new_optimizations = true,
        },
    },
})

hl.layer_rule({ name = "pill-blur", match = { namespace = "pill" }, blur = true, ignore_alpha = 0.01 })
hl.layer_rule({ name = "quickshell-blur", match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.01 })
hl.layer_rule({ name = "launcher-blur", match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.01 })
hl.layer_rule({ name = "lock-blur", match = { namespace = "lock" }, blur = true, ignore_alpha = 0.01 })
