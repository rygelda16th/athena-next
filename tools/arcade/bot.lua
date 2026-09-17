-- C1: a bot that plays the arcade game through for the capture, when no person does.
-- Loaded by tools/arcade/capture.lua (CAPTURE_BOT). It inserts a coin, starts, holds
-- the player's energy, lives and clock (addresses found by tools/arcade RAM search:
-- energy $FD17 against the LIFE bar, lives $FD2E, the clock's BCD seconds $FE1C; the
-- world number is $FD35, IY+$2D with IY = $FD08, read by the title at $06C1), and
-- walks right, attacking and jumping; when the background stops scrolling it tries
-- other moves in turn. A person's play-through is better (every move, every item);
-- this one is provisional.

local ENERGY, LIVES, SECONDS, WORLD = 0xfd17, 0xfd2e, 0xfe1c, 0xfd35
local STRATEGIES = {
    {right = true, jump_every = 48, frames = 600},
    {right = true, jump_every = 10, frames = 240},
    {up = true, jump_every = 0, frames = 120},
    {right = true, up = true, jump_every = 16, frames = 240},
    {down = true, jump_every = 0, frames = 90},
    {right = true, down = true, jump_every = 0, frames = 120},
    {left = true, jump_every = 20, frames = 60},
    {up = true, jump_every = 8, frames = 180},
    {right = true, jump_every = 5, frames = 240},
}
local strategy, used, visited, since_new = 1, 0, {}, 0

local function set(ports, port, field, on)
    ports[port].fields[field]:set_value(on and 1 or 0)
end

-- Progress is reaching a place not seen before (the background scroll, in 32-pixel
-- steps, and the world number); a strategy runs until its time is up without progress,
-- then the next is tried.
return function(frame, space, ports)
    set(ports, ":IN0", "Coin 1", frame % 3000 >= 600 and frame % 3000 < 612)
    set(ports, ":IN0", "1 Player Start", frame % 3000 >= 700 and frame % 3000 < 712)
    if frame < 700 then return end
    if space:read_u8(LIVES) > 0 and space:read_u8(LIVES) < 3 then space:write_u8(LIVES, 3) end
    if space:read_u8(ENERGY) > 0 then space:write_u8(ENERGY, 12) end
    if space:read_u8(SECONDS) == 0x10 then space:write_u8(SECONDS, 0x59) end
    local scroll = capture_scroll or {}
    local key = space:read_u8(WORLD) .. ":" .. ((scroll.bgx or 0) // 32) .. ":" .. ((scroll.bgy or 0) // 32)
    if not visited[key] then
        visited[key] = true
        since_new = 0
    else
        since_new = since_new + 1
    end
    used = used + 1
    local s = STRATEGIES[strategy]
    if since_new > s.frames then
        strategy = strategy % #STRATEGIES + 1
        since_new, used = 0, 0
        s = STRATEGIES[strategy]
    elseif used > s.frames * 4 and strategy ~= 1 then
        strategy, used = 1, 0
        s = STRATEGIES[strategy]
    end
    set(ports, ":IN1", "P1 Right", s.right)
    set(ports, ":IN1", "P1 Left", s.left)
    set(ports, ":IN1", "P1 Up", s.up)
    set(ports, ":IN1", "P1 Down", s.down)
    set(ports, ":IN1", "P1 Button 1", frame % 8 < 3)
    set(ports, ":IN1", "P1 Button 2", s.jump_every > 0 and frame % s.jump_every < 3)
end
