Font = {}
Font.default = "CaskaydiaCode NFM"

-- Search directories, built once: $PATH entries first, then common
-- Nix/Homebrew/system fallbacks. Deduplicated so we never stat a dir twice.
local resolvebinDirs = {}
do
  local seen = {}
  local function add(dir)
    if dir and dir ~= "" and not seen[dir] then
      seen[dir] = true
      resolvebinDirs[#resolvebinDirs + 1] = dir
    end
  end
  for dir in (os.getenv "PATH" or ""):gmatch "[^:]+" do
    add(dir)
  end
  add((os.getenv "HOME" or "") .. "/.nix-profile/bin")
  add "/run/current-system/sw/bin"
  add "/opt/homebrew/bin"
  add "/usr/local/bin"
  add "/usr/bin"
  add "/bin"
end

-- Memoized: each binary is stat-resolved at most once (false = not found).
local resolvebinCache = {}
function resolvebin(bin)
  local cached = resolvebinCache[bin]
  if cached ~= nil then
    return cached or nil
  end
  for _, dir in ipairs(resolvebinDirs) do
    local p = dir .. "/" .. bin
    -- Request only the "mode" attribute instead of the full table.
    if hs.fs.attributes(p, "mode") then
      resolvebinCache[bin] = p
      return p
    end
  end
  resolvebinCache[bin] = false
  return nil
end

require "prefs"
require "binds"
require "WindowManager"
-- require "vim"
