# Option 5, define keys, answered Y; then left alone.
OUT = "build/g2/script-acceptkeys"
FRAMES = 4000


def pulses(first, key, n=4):
    """The menu waits for all keys up ($C2E6) before it polls, and one tap can miss
    the poll: 3 frames down, 12 up, n times."""
    return [(first + 15 * i, first + 15 * i + 3, key) for i in range(n)]

PRESS = pulses(150, "5", 8)
for i, k in enumerate(["P", "O", "Q", "A", "SPACE", "Y"]):
    PRESS += pulses(300 + 90 * i, k)
SHOTS = list(range(150, 4000, 100))
