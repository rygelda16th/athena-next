# Option 1, keyboard, then no input at all for twenty minutes of game time:
# every life lost, every CONTINUE? unanswered, game over, back to the title.
OUT = "build/g2/script-gameover"
FRAMES = 60000


def pulses(first, key, n=4):
    """The menu waits for all keys up ($C2E6) before it polls, and one tap can miss
    the poll: 3 frames down, 12 up, n times."""
    return [(first + 15 * i, first + 15 * i + 3, key) for i in range(n)]

PRESS = pulses(150, "1", 8)
SHOTS = list(range(150, 60000, 1500))
SNAP = False
