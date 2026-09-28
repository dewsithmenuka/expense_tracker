from PIL import Image, ImageDraw
import os

S = 1024
K = 0.82  # keep the artwork inside the "safe zone" the OS may crop


def P(f):  # position
    return S * (0.5 + (f - 0.5) * K)


def L(f):  # length
    return S * f * K


img = Image.new("RGB", (S, S))
px = img.load()
c1, c2 = (0x00, 0x89, 0x7B), (0x00, 0x4D, 0x40)
for y in range(S):
    for x in range(S):
        t = (x + y) / (2 * (S - 1))
        px[x, y] = tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

d = ImageDraw.Draw(img)
bar_w, gap, base = 0.13, 0.07, 0.78
start = (1 - (3 * bar_w + 2 * gap)) / 2
heights = (0.18, 0.28, 0.40)

for i, h in enumerate(heights):
    x0 = start + i * (bar_w + gap)
    d.rounded_rectangle(
        (P(x0), P(base - h), P(x0 + bar_w), P(base)),
        radius=L(bar_w) / 2,
        fill="white",
    )

cx = start + 2 * (bar_w + gap) + bar_w / 2
r = 0.12
cy = base - heights[-1] - r
d.ellipse((P(cx - r), P(cy - r), P(cx + r), P(cy + r)), fill=(255, 193, 7))
r2 = r * 0.68
d.ellipse(
    (P(cx - r2), P(cy - r2), P(cx + r2), P(cy + r2)),
    outline=(255, 160, 0),
    width=int(L(r * 0.16)),
)

os.makedirs("assets", exist_ok=True)
img.save("assets/icon.png")
print("Saved assets/icon.png")