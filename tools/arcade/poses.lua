-- C2: the arcade player's poses, captured on cue. A bot for tools/arcade/capture.lua
-- (CAPTURE_BOT) that starts a game and then runs a fixed list of moves in world 1,
-- each for a set number of frames, holding energy, lives and the clock as bot.lua does.
-- It writes the frame where each move starts to CAPTURE_OUT with ".moves" added, so
-- tools/arcade/poses.py can tie every sprite table to the move that produced it.

local ENERGY, LIVES, SECONDS = 0xfd17, 0xfd2e, 0xfe1c
local START = 1500
local MOVES = {
    {"stand", 120, {}},
    {"walk-right", 240, {right = true}},
    {"stand", 60, {}},
    {"walk-left", 120, {left = true}},
    {"turn-right", 30, {right = true}},
    {"jump", 180, {jump_every = 60}},
    {"crouch", 120, {down = true}},
    {"attack", 160, {fire_every = 16}},
    {"crouch-attack", 160, {down = true, fire_every = 16}},
    {"walk-attack", 160, {right = true, fire_every = 16}},
    {"jump-attack", 180, {jump_every = 60, fire_every = 10}},
    {"attack-left", 160, {left = true, fire_every = 16}},
    {"up", 120, {up = true}},
    {"walk-right", 400, {right = true, jump_every = 50}},
}
local moves_file = assert(io.open((os.getenv("CAPTURE_OUT") or "build/c1/capture.bin") .. ".moves", "w"))
local at, index = START, 1

local function set(ports, port, field, on)
    ports[port].fields[field]:set_value(on and 1 or 0)
end

return function(frame, space, ports)
    set(ports, ":IN0", "Coin 1", frame >= 600 and frame < 612)
    set(ports, ":IN0", "1 Player Start", frame >= 700 and frame < 712)
    if frame < 700 then return end
    if space:read_u8(LIVES) > 0 and space:read_u8(LIVES) < 3 then space:write_u8(LIVES, 3) end
    if space:read_u8(ENERGY) > 0 then space:write_u8(ENERGY, 12) end
    if space:read_u8(SECONDS) == 0x10 then space:write_u8(SECONDS, 0x59) end
    if frame < START then return end
    local move = MOVES[index]
    if not move then
        for _, f in ipairs({"P1 Right", "P1 Left", "P1 Up", "P1 Down", "P1 Button 1", "P1 Button 2"}) do
            set(ports, ":IN1", f, false)
        end
        return
    end
    if frame == at then
        moves_file:write(string.format("%d %s\n", frame, move[1]))
        moves_file:flush()
    end
    local m, t = move[3], frame - at
    set(ports, ":IN1", "P1 Right", m.right)
    set(ports, ":IN1", "P1 Left", m.left)
    set(ports, ":IN1", "P1 Up", m.up)
    set(ports, ":IN1", "P1 Down", m.down)
    set(ports, ":IN1", "P1 Button 1", m.fire_every and t % m.fire_every < 3)
    set(ports, ":IN1", "P1 Button 2", m.jump_every and t % m.jump_every < 3)
    if t + 1 >= move[2] then
        at, index = frame + 1, index + 1
    end
end
