# Option 2, Kempston joystick; then left alone.
OUT = "build/g2/script-option2"
FRAMES = 3000


def pulses(first, key, n=4):
    """The menu waits for all keys up ($C2E6) before it polls, and one tap can miss
    the poll: 3 frames down, 12 up, n times."""
    return [(first + 15 * i, first + 15 * i + 3, key) for i in range(n)]

PRESS = pulses(150, "2", 8)
SHOTS = list(range(150, 3000, 100))
