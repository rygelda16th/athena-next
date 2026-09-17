-- C1: the arcade capture. Runs inside MAME 0.251 with the player's own `athena` set:
--
--   mame athena -rompath data/arcade -autoboot_script tools/arcade/capture.lua ...
--
-- Every frame it logs what the arcade's video hardware shows and what the main CPU
-- sends to the sound board, so tools/arcade/ can rebuild any frame and tie sounds to
-- game events. Environment (read at start):
--   CAPTURE_OUT      the log file to write (default build/c1/capture.bin)
--   CAPTURE_FRAMES   frames to run before exiting (0 = until MAME stops)
--   CAPTURE_SNAPS    comma-separated frame numbers at which to save a MAME snapshot
--   CAPTURE_BOT      Lua file with a bot: a function bot(frame, cpu, ports) called each
--                    frame before logging (optional; tools/arcade/bot.lua)
--
-- LOG FORMAT (little-endian), a stream of records:
--   'F' u32 frame                          frame start; the records after it belong to it
--   'S' 200 bytes                          sprite table $D000-$D0C7, when it changed
--   'V' u16 offset u8 value                a write to background video RAM ($D800 + offset,
--                                          either CPU)
--   'T' u16 offset u8 value                a write to text video RAM ($F800 + offset, either CPU)
--   'R' u8 register u8 value               a write to $C800 (attrs), $C900/$CA00 (sprite
--                                          scroll y/x), $CB00/$CC00 (background scroll y/x):
--                                          register = high byte ($C8-$CC)
--   'C' u8 command                         a sound command written to $C400
--   'M' 8192 bytes                          the whole background video RAM (first record)
-- Only the player's files are read; the log stays in build/.

local out_path = os.getenv("CAPTURE_OUT") or "build/c1/capture.bin"
local max_frames = tonumber(os.getenv("CAPTURE_FRAMES") or "0")
local snaps = {}
for n in string.gmatch(os.getenv("CAPTURE_SNAPS") or "", "%d+") do snaps[tonumber(n)] = true end

local cpu = manager.machine.devices[":maincpu"]
local space = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))
local frame = 0
local last_sprites = ""
-- The taps must stay referenced: MAME removes a tap when Lua collects its handler.
capture_taps = {}
local taps = capture_taps

local function u16(v) return string.char(v & 255, (v >> 8) & 255) end
local function u32(v) return string.char(v & 255, (v >> 8) & 255, (v >> 16) & 255, (v >> 24) & 255) end

do  -- the background video RAM as it is before the first logged write
    local t = {}
    for a = 0xd800, 0xf7ff do t[#t + 1] = string.char(space:read_u8(a)) end
    f:write("M", table.concat(t))
end

taps[#taps + 1] = space:install_write_tap(0xd800, 0xf7ff, "bgram", function(offset, data, mask)
    f:write("V", u16(offset - 0xd800), string.char(data & 255))
end)
taps[#taps + 1] = space:install_write_tap(0xf800, 0xffff, "txram", function(offset, data, mask)
    f:write("T", u16(offset - 0xf800), string.char(data & 255))
end)
-- The second CPU writes the same video RAM through its own map (MAME tnk3_cpuB_map):
-- sprites at $C800-$CFFF, background at $D000-$EFFF, text at $F800-$FFFF.
local sub = manager.machine.devices[":sub"].spaces["program"]
taps[#taps + 1] = sub:install_write_tap(0xd000, 0xefff, "bgram_b", function(offset, data, mask)
    f:write("V", u16(offset - 0xd000), string.char(data & 255))
end)
taps[#taps + 1] = sub:install_write_tap(0xf800, 0xffff, "txram_b", function(offset, data, mask)
    f:write("T", u16(offset - 0xf800), string.char(data & 255))
end)

capture_scroll = {reg = {}}           -- for a bot: the background scroll as written
taps[#taps + 1] = space:install_write_tap(0xc800, 0xccff, "videoreg", function(offset, data, mask)
    if offset & 0xff == 0 then
        f:write("R", string.char(offset >> 8), string.char(data & 255))
        local reg = capture_scroll.reg
        reg[offset >> 8] = data & 255
        local attr = reg[0xc8] or 0
        capture_scroll.bgx = (reg[0xcc] or 0) | ((attr & 0x02) << 7)
        capture_scroll.bgy = (reg[0xcb] or 0) | ((attr & 0x10) << 4)
    end
end)
taps[#taps + 1] = space:install_write_tap(0xc400, 0xc400, "sound", function(offset, data, mask)
    f:write("C", string.char(data & 255))
end)

local bot = nil
local bot_path = os.getenv("CAPTURE_BOT")
if bot_path and bot_path ~= "" then
    bot = dofile(bot_path)
end

emu.register_frame_done(function()
    frame = frame + 1
    f:write("F", u32(frame))
    local t = {}
    for a = 0xd000, 0xd0c7 do t[#t + 1] = string.char(space:read_u8(a)) end
    local s = table.concat(t)
    if s ~= last_sprites then
        f:write("S", s)
        last_sprites = s
    end
    if bot then bot(frame, space, manager.machine.ioport.ports) end
    if snaps[frame] then manager.machine.video:snapshot() end
    if max_frames > 0 and frame >= max_frames then
        f:close()
        manager.machine:exit()
    end
end, "capture")
