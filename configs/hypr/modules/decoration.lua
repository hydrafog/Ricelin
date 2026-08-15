local home = os.getenv("HOME")
local ok, wc = pcall(dofile, home .. "/.cache/ricelin/hypr-colors.lua")
if not ok then wc = nil end

local function border(hex, fallback)
    if type(hex) ~= "string" then hex = fallback end
    return "rgb(" .. hex:gsub("#", "") .. ")"
end

local active   = border(wc and wc.active, "919191")
local inactive = active

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
            enabled           = false,
            size              = 5,
            passes            = 2,
            vibrancy          = 0.25,
            noise             = 0.01,
            new_optimizations = false,
        },
    },
})
