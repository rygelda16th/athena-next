-- E5: capture one arcade sound command's chip writes, from the player's own arcade set.
--
--   SOUND_CMD=n SOUND_OUT=file SOUND_SECONDS=s mame athena ... -autoboot_script tools/arcade/soundcmd.lua
--
-- Demo sounds are switched off, the game is left to finish its power-on test, and at
-- SEND_FRAME the command byte is written to the main CPU's sound latch ($C400), as the
-- game itself does. From then every write the sound CPU makes to the two YM3526 FM
-- chips is logged with its emulated time, for SOUND_SECONDS seconds:
--   u32 microseconds since the command, u8 chip (0 or 1), u8 register, u8 value
-- Any command the main CPU sends itself in that time is logged as chip 255, register
-- 255, value = the command, so a capture it disturbed can be recognised.

local cmd = tonumber(os.getenv("SOUND_CMD"))
local out_path = os.getenv("SOUND_OUT")
local seconds = tonumber(os.getenv("SOUND_SECONDS") or "20")
local SEND_FRAME = 400

local main = manager.machine.devices[":maincpu"].spaces["program"]
local snd = manager.machine.devices[":audiocpu"].spaces["program"]
local f = assert(io.open(out_path, "wb"))
local frame, t0, reg = 0, nil, {0, 0}

local function now_us()
    local t = manager.machine.time
    return t.seconds * 1000000 + t.attoseconds // 1000000000000
end

local function record(chip, r, v)
    if not t0 then return end
    local us = now_us() - t0
    f:write(string.char(us & 255, (us >> 8) & 255, (us >> 16) & 255, (us >> 24) & 255, chip, r, v))
end

sound_taps = {}
sound_taps[1] = snd:install_write_tap(0xe800, 0xe800, "ym1a", function(o, d) reg[1] = d end)
sound_taps[2] = snd:install_write_tap(0xec00, 0xec00, "ym1d", function(o, d) record(0, reg[1], d) end)
sound_taps[3] = snd:install_write_tap(0xf000, 0xf000, "ym2a", function(o, d) reg[2] = d end)
sound_taps[4] = snd:install_write_tap(0xf400, 0xf400, "ym2d", function(o, d) record(1, reg[2], d) end)
sound_taps[5] = main:install_write_tap(0xc400, 0xc400, "latch", function(o, d)
    if t0 and not sending then record(255, 255, d) end
end)

local dsw2 = manager.machine.ioport.ports[":DSW2"].fields["Demo Sounds"]
dsw2.user_value = 0x04                  -- demo sounds off

emu.register_frame_done(function()
    frame = frame + 1
    if frame == SEND_FRAME then
        t0 = now_us()
        sending = true
        main:write_u8(0xc400, cmd)
        sending = false
    end
    if t0 and now_us() - t0 > seconds * 1000000 then
        f:close()
        manager.machine:exit()
    end
end, "soundcmd")
