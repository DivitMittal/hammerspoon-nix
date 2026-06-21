Font = {}
Font.default = "CaskaydiaCode NFM"

function resolvebin(bin)
  for dir in (os.getenv("PATH") or ""):gmatch("[^:]+") do
    local p = dir .. "/" .. bin
    if hs.fs.attributes(p) then return p end
  end
  for _, dir in ipairs({
    (os.getenv("HOME") or "") .. "/.nix-profile/bin",
    "/run/current-system/sw/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
  }) do
    local p = dir .. "/" .. bin
    if hs.fs.attributes(p) then return p end
  end
end

require "prefs"
require "binds"
require "WindowManager"
-- require "vim"
