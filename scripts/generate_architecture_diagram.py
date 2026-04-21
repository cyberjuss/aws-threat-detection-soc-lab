"""Generate the architecture diagram image for the AWS SOC lab."""

from __future__ import annotations

import math
from pathlib import Path
from textwrap import wrap

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "diagrams"
OUT_PATH = OUT_DIR / "aws-threat-detection-soc-lab-architecture.png"

W, H = 1800, 760

COLORS = {
    "bg": "#101214",
    "grid": "#33373d",
    "panel": "#121416",
    "panel_border": "#d0d7df",
    "text": "#f2f5f8",
    "muted": "#c6cbd1",
    "aws_orange": "#ff9900",
    "s3_green": "#7aa116",
    "sqs_pink": "#ff65c8",
    "iam_green": "#72c471",
    "splunk_gray": "#6f747b",
    "blue": "#4c8dde",
    "purple": "#8f5edb",
    "red": "#f05b5b",
    "line": "#d9dde3",
}


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


F_TITLE = font(19, True)
F_PANEL = font(18, True)
F_NODE = font(15, True)
F_BODY = font(13)
F_LABEL = font(12, True)
F_SMALL = font(11)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def center_text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fnt: ImageFont.ImageFont, fill: str) -> None:
    x, y = xy
    tw, th = text_size(draw, text, fnt)
    draw.text((x - tw / 2, y - th / 2), text, font=fnt, fill=fill)


def draw_wrapped_center(draw: ImageDraw.ImageDraw, center: tuple[int, int], text: str, fnt: ImageFont.ImageFont, fill: str, max_width: int, line_gap: int = 3) -> None:
    avg_char = max(6, text_size(draw, "abcdefghijklmnopqrstuvwxyz", fnt)[0] / 26)
    chars = max(8, int(max_width / avg_char))
    lines: list[str] = []
    for raw in text.splitlines():
        lines.extend(wrap(raw, width=chars) or [""])
    heights = [text_size(draw, line or "Ag", fnt)[1] for line in lines]
    total_h = sum(heights) + line_gap * (len(lines) - 1)
    x, y = center[0], center[1] - total_h // 2
    for line, lh in zip(lines, heights):
        tw, _ = text_size(draw, line, fnt)
        draw.text((x - tw / 2, y), line, font=fnt, fill=fill)
        y += lh + line_gap


def grid(draw: ImageDraw.ImageDraw) -> None:
    for x in range(0, W, 44):
        draw.line([(x, 0), (x, H)], fill=COLORS["grid"], width=1)
    for y in range(0, H, 44):
        draw.line([(0, y), (W, y)], fill=COLORS["grid"], width=1)
    for x in range(0, W, 220):
        draw.line([(x, 0), (x, H)], fill="#4b4f56", width=1)
    for y in range(0, H, 220):
        draw.line([(0, y), (W, y)], fill="#4b4f56", width=1)


def panel(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], title: str) -> None:
    draw.rectangle(box, outline=COLORS["panel_border"], width=2, fill=COLORS["panel"])
    draw.text((box[0] + 10, box[1] + 8), title, font=F_TITLE, fill=COLORS["text"])


def arrow_head(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], color: str) -> None:
    sx, sy = start
    ex, ey = end
    angle = math.atan2(ey - sy, ex - sx)
    head_len = 12
    head_angle = math.pi / 7
    p1 = (ex - head_len * math.cos(angle - head_angle), ey - head_len * math.sin(angle - head_angle))
    p2 = (ex - head_len * math.cos(angle + head_angle), ey - head_len * math.sin(angle + head_angle))
    draw.polygon([end, p1, p2], fill=color)


def arrow(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], label: str | None = None, label_xy: tuple[int, int] | None = None, color: str = COLORS["line"], width: int = 2) -> None:
    draw.line(pts, fill=color, width=width, joint="curve")
    arrow_head(draw, pts[-2], pts[-1], color)
    if label and label_xy:
        draw_label(draw, label_xy, label, color)


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, color: str = COLORS["text"]) -> None:
    x, y = xy
    lines = text.split("\n")
    widths = [text_size(draw, line, F_LABEL)[0] for line in lines]
    heights = [text_size(draw, line, F_LABEL)[1] for line in lines]
    pad = 5
    box = (x - max(widths) // 2 - pad, y - sum(heights) // 2 - pad, x + max(widths) // 2 + pad, y + sum(heights) // 2 + 6 + pad)
    draw.rounded_rectangle(box, radius=6, fill=COLORS["bg"], outline="#555b64", width=1)
    yy = box[1] + pad
    for line, lh in zip(lines, heights):
        tw = text_size(draw, line, F_LABEL)[0]
        draw.text((x - tw / 2, yy), line, font=F_LABEL, fill=color)
        yy += lh + 2


def aws_icon_box(draw: ImageDraw.ImageDraw, xy: tuple[int, int], color: str, title: str, subtitle: str, icon: str) -> tuple[int, int, int, int]:
    x, y = xy
    draw.rectangle((x, y, x + 64, y + 64), fill=color, outline="#f2f2f2", width=1)
    center_text(draw, (x + 32, y + 31), icon, font(24, True), "#151515")
    draw_wrapped_center(draw, (x + 32, y + 90), title, F_NODE, COLORS["text"], 130)
    if subtitle:
        draw_wrapped_center(draw, (x + 32, y + 123), subtitle, F_SMALL, COLORS["muted"], 145)
    return (x, y, x + 64, y + 64)


def user_icon(draw: ImageDraw.ImageDraw, xy: tuple[int, int], label: str, color: str) -> tuple[int, int, int, int]:
    x, y = xy
    draw.ellipse((x + 20, y, x + 50, y + 30), outline=color, width=3)
    draw.line([(x + 35, y + 30), (x + 35, y + 78)], fill=color, width=3)
    draw.arc((x, y + 35, x + 70, y + 105), 205, 335, fill=color, width=3)
    draw_wrapped_center(draw, (x + 35, y + 125), label, F_NODE, COLORS["text"], 230)
    return (x, y, x + 70, y + 105)


def server_icon(draw: ImageDraw.ImageDraw, xy: tuple[int, int], title: str, subtitle: str) -> tuple[int, int, int, int]:
    x, y = xy
    draw.rectangle((x, y, x + 70, y + 86), fill=COLORS["splunk_gray"], outline="#e4e4e4", width=1)
    for i in range(4):
        draw.rectangle((x + 13, y + 16 + i * 14, x + 57, y + 20 + i * 14), fill="#111111")
    draw_wrapped_center(draw, (x + 35, y + 120), title, F_NODE, COLORS["text"], 130)
    draw_wrapped_center(draw, (x + 35, y + 148), subtitle, F_SMALL, COLORS["muted"], 140)
    return (x, y, x + 70, y + 86)


def search_icon(draw: ImageDraw.ImageDraw, xy: tuple[int, int]) -> tuple[int, int, int, int]:
    x, y = xy
    draw.ellipse((x, y, x + 56, y + 56), outline=COLORS["blue"], width=6)
    draw.line((x + 44, y + 44, x + 78, y + 78), fill=COLORS["blue"], width=8)
    draw_wrapped_center(draw, (x + 40, y + 118), "Search\n& Reporting", F_NODE, COLORS["text"], 140)
    return (x, y, x + 78, y + 78)


def dashboard_icon(draw: ImageDraw.ImageDraw, xy: tuple[int, int]) -> tuple[int, int, int, int]:
    x, y = xy
    draw.rectangle((x, y, x + 82, y + 64), fill="#d6d8dc", outline="#f5f5f5", width=1)
    for i, h in enumerate([22, 38, 30, 48]):
        draw.rectangle((x + 12 + i * 16, y + 54 - h, x + 22 + i * 16, y + 54), fill="#555b64")
    draw.line((x + 8, y + 12, x + 28, y + 28, x + 44, y + 18, x + 68, y + 34), fill="#333333", width=3)
    draw.rectangle((x + 30, y + 64, x + 52, y + 78), fill="#d6d8dc")
    draw.line((x + 15, y + 80, x + 67, y + 80), fill="#d6d8dc", width=4)
    draw_wrapped_center(draw, (x + 41, y + 115), "Dashboard", F_NODE, COLORS["text"], 120)
    return (x, y, x + 82, y + 80)


def terraform_icon(draw: ImageDraw.ImageDraw, xy: tuple[int, int]) -> None:
    x, y = xy
    col = "#7b42bc"
    draw.polygon([(x, y), (x + 24, y + 12), (x + 24, y + 40), (x, y + 28)], fill=col)
    draw.polygon([(x + 28, y + 14), (x + 52, y + 2), (x + 52, y + 30), (x + 28, y + 42)], fill=col)
    draw.polygon([(x + 28, y + 48), (x + 52, y + 36), (x + 52, y + 64), (x + 28, y + 76)], fill=col)


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    image = Image.new("RGB", (W, H), COLORS["bg"])
    draw = ImageDraw.Draw(image)
    grid(draw)

    panel(draw, (18, 28, 1185, 712), "AWS Cloud")
    panel(draw, (1365, 170, 1780, 585), "Docker Desktop (Local)")

    cloudtrail = aws_icon_box(draw, (235, 110), "#ff74d2", "CloudTrail", "", "CT")
    s3_ct = aws_icon_box(draw, (505, 124), COLORS["s3_green"], "S3 Bucket", "soc-lab-cloudtrail", "S3")
    sqs_ct = aws_icon_box(draw, (835, 110), COLORS["sqs_pink"], "SQS Queue", "cloudtrail-s3-events", "SQS")

    target_box = (215, 275, 565, 432)
    draw.rectangle(target_box, outline=COLORS["purple"], width=2, fill="#16151f")
    compute = aws_icon_box(draw, (250, 305), COLORS["aws_orange"], "Stratus\nTarget", "", "EC2")
    vpcflow = aws_icon_box(draw, (475, 330), COLORS["purple"], "VPC Flow Log", "", "VPC")
    draw_label(draw, (402, 312), "Generates\nNetwork Traffic")
    arrow(draw, [(315, 337), (474, 360)], color=COLORS["line"], width=2)

    attacker = user_icon(draw, (365, 540), "soc-lab-stratus\nAttacker", COLORS["red"])
    s3_vpc = aws_icon_box(draw, (585, 545), COLORS["s3_green"], "S3 Bucket", "soc-lab-vpcflow", "S3")
    sqs_vpc = aws_icon_box(draw, (835, 545), COLORS["sqs_pink"], "SQS Queue", "vpcflow-s3-events", "SQS")
    splunk_user = user_icon(draw, (1040, 335), "soc-lab-splunk-addon", COLORS["iam_green"])
    terraform_icon(draw, (720, 650))

    server = server_icon(draw, (1445, 322), "Splunk Server", "AWS Add-on")
    search = search_icon(draw, (1600, 250))
    dashboard = dashboard_icon(draw, (1595, 455))

    # AWS telemetry paths.
    arrow(draw, [(299, 142), (505, 142)], "Writes Logs", (415, 126), COLORS["line"])
    arrow(draw, [(569, 142), (835, 142)], "New Object\nNotification", (700, 124), COLORS["line"])
    arrow(draw, [(539, 432), (539, 545)], "Writes Logs", (603, 492), COLORS["line"])
    arrow(draw, [(649, 577), (835, 577)], "New Object\nNotification", (742, 556), COLORS["line"])

    # Stratus action and recording paths.
    arrow(draw, [(400, 540), (400, 432)], color=COLORS["red"], width=2)
    arrow(draw, [(400, 540), (113, 540), (113, 142), (235, 142)], "Perform AWS\nAPI Actions", (84, 360), COLORS["red"])

    # Splunk IAM reads SQS and S3 data before local Splunk ingests it.
    arrow(draw, [(899, 142), (990, 142), (990, 365), (1040, 365)], "Read logs to ingest\nto Splunk", (1010, 277), COLORS["line"])
    arrow(draw, [(899, 577), (990, 577), (990, 395), (1040, 395)], "Read logs to ingest\nto Splunk", (1010, 490), COLORS["line"])
    arrow(draw, [(1110, 382), (1445, 382)], "Poll logs from\nspecified S3 buckets", (1265, 360), COLORS["line"])

    # Splunk app flow.
    arrow(draw, [(1515, 346), (1558, 346), (1558, 288), (1600, 288)], color=COLORS["line"], width=2)
    arrow(draw, [(1640, 328), (1640, 455)], color=COLORS["line"], width=2)

    # Small service hint in local panel.
    draw.text((1380, 188), "Docker", font=F_SMALL, fill=COLORS["muted"])
    draw.ellipse((1382, 207, 1425, 225), fill="#4c8dde")
    draw.rectangle((1390, 197, 1405, 210), fill="#4c8dde")
    draw.rectangle((1407, 197, 1422, 210), fill="#4c8dde")

    image.save(OUT_PATH)
    print(f"Wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
