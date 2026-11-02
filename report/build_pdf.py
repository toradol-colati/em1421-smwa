"""Build report/EM1421_Repeat_RfA_Report.pdf from report/report_source.md.

Run from the repository root after Rscript R/00_run_all.R, so the figures in
output/figures/ are current:

    python report/build_pdf.py

Needs Python 3 with reportlab (pip install reportlab). The source is plain
markdown with three extensions used by this report: "# " title, "## " and
"### " headings, and [[FIGURE:<path>|<caption>]] lines for figures.
"""
import re
import sys
from pathlib import Path

from reportlab.lib.enums import TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Image, KeepTogether, Paragraph, SimpleDocTemplate, Spacer

SRC = Path("report/report_source.md")
OUT = Path("report/EM1421_Repeat_RfA_Report.pdf")
HEADER = "EM1421 | Social Media and Web Analytics"
SHORT_TITLE = "Repeat Requests for Adminship"

styles = getSampleStyleSheet()
body = ParagraphStyle("body", parent=styles["BodyText"], fontName="Times-Roman", fontSize=10.5,
                      leading=14, alignment=TA_JUSTIFY, spaceAfter=6)
title = ParagraphStyle("title", parent=styles["Title"], fontName="Times-Bold", fontSize=17,
                       leading=21, spaceAfter=8)
meta = ParagraphStyle("meta", parent=body, alignment=0, spaceAfter=2)
h2 = ParagraphStyle("h2", parent=styles["Heading2"], fontName="Times-Bold", fontSize=13,
                    spaceBefore=10, spaceAfter=4)
h3 = ParagraphStyle("h3", parent=styles["Heading3"], fontName="Times-Bold", fontSize=11.5,
                    spaceBefore=8, spaceAfter=3)
caption = ParagraphStyle("caption", parent=body, fontSize=9, leading=11.5, spaceAfter=10)
ref = ParagraphStyle("ref", parent=body, fontSize=9.5, leading=12, leftIndent=14, firstLineIndent=-14,
                     alignment=0)


def inline(text):
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*(.+?)\*", r"<i>\1</i>", text)
    return text


def figure(path, cap, width):
    img = Image(path)
    scale = width / img.imageWidth
    img.drawWidth, img.drawHeight = width, img.imageHeight * scale
    return KeepTogether([img, Spacer(1, 4), Paragraph(inline(cap), caption)])


def page(canvas, doc):
    canvas.saveState()
    canvas.setFont("Times-Roman", 8.5)
    w, h = A4
    canvas.drawString(doc.leftMargin, h - 1.2 * cm, HEADER)
    canvas.drawString(doc.leftMargin, 1.0 * cm, SHORT_TITLE)
    canvas.drawRightString(w - doc.rightMargin, 1.0 * cm, str(doc.page))
    canvas.restoreState()


def build():
    lines = SRC.read_text(encoding="utf-8").splitlines()
    doc = SimpleDocTemplate(str(OUT), pagesize=A4, leftMargin=2.2 * cm, rightMargin=2.2 * cm,
                            topMargin=2.0 * cm, bottomMargin=1.8 * cm,
                            title=SHORT_TITLE, author="Mihretab Worku Morka and Umberto Toraldo")
    width = A4[0] - doc.leftMargin - doc.rightMargin
    story, para, in_refs, n_meta = [], [], False, 0

    def flush():
        nonlocal para
        if para:
            story.append(Paragraph(inline(" ".join(para)), ref if in_refs else body))
            para = []

    for line in lines:
        s = line.strip()
        if not s:
            flush()
            continue
        m = re.match(r"\[\[FIGURE:(.+?)\|(.+)\]\]$", s)
        if m:
            flush()
            if not Path(m.group(1)).exists():
                sys.exit(f"missing figure: {m.group(1)}")
            story.append(figure(m.group(1), m.group(2), width))
        elif s.startswith("### "):
            flush(); story.append(Paragraph(inline(s[4:]), h3))
        elif s.startswith("## "):
            flush(); in_refs = s[3:].strip().lower() == "references"
            story.append(Paragraph(inline(s[3:]), h2))
        elif s.startswith("# "):
            flush(); story.append(Paragraph(inline(s[2:]), title))
        elif not story or (len(story) <= 2 and n_meta < 2 and not para):
            story.append(Paragraph(inline(s), meta)); n_meta += 1
        else:
            para.append(s)
    flush()
    doc.build(story, onFirstPage=page, onLaterPages=page)

    # character count, as the course rule measures it (text including spaces,
    # figure captions included, figure markers' paths excluded)
    text = re.sub(r"\[\[FIGURE:[^|]*\|(.*?)\]\]", r"\1", SRC.read_text(encoding="utf-8"))
    text = re.sub(r"^#+ ", "", text, flags=re.M)
    print(f"written {OUT}; source text {len(text)} characters including spaces")


if __name__ == "__main__":
    build()
