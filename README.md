# The Tao of Silica

LaTeX source for the book. Built on the `memoir` class with LuaLaTeX.

## Build

    latexmk          # builds build/main.pdf
    latexmk -pvc     # rebuilds automatically on every save
    latexmk -c       # removes intermediate files

## Releasing a PDF

GitHub Actions builds the book and attaches the PDF to a release whenever a
tag is pushed (`.github/workflows/release-pdf.yml`). Tags starting `draft-`
become pre-releases; `v*` tags become full releases.

    git tag draft-2026-11-20
    git push origin draft-2026-11-20

The PDF is not committed to the repository; it lives on the release page.

## Layout

| Path | Contents |
|---|---|
| `main.tex` | Book metadata (title, subtitle, author) and chapter order |
| `taosilica.sty` | House style: page size, fonts, colours, chapter style, cover, sidebars, asides |
| `frontmatter/` | Title page, copyright page, acknowledgments, preface |
| `chapters/ch01.tex` – `ch12.tex` | One file per chapter: Part I (1 Why? and Why Not?, 2 How We Got Here), Part II (3–12, the ten principles) |
| `templates/showcase.tex` | Sample of every book element (chart, diagram, sidebox, aside, footnotes); not included in the book |
| `research/` | Cited research notes drawn from the Silica, SwErl, BEAM_SEMP, BEES and Unsafe Impedance sources, plus `chapter-map.md` |
| `interviews/` | Interview transcripts, progress log and style decisions |
| `.claude/skills/ghostwriter/` | The journalist/ghostwriter interview skill |
| `figures/` | TikZ diagrams and pgfplots charts (`\input` into figures) |
| `data/` | CSV data for charts |
| `images/` | Cover art (`images/cover.jpg`) and other images |

## Writing commands

| Element | Command |
|---|---|
| Footnote | `\footnote{...}` |
| Margin aside | `\aside{...}` |
| Boxed sidebar | `\begin{sidebox}[Optional title] ... \end{sidebox}` |
| Footnote inside a sidebox, at page bottom | `\boxfootnote{...}` |
| Chart or table wider than the text | `\begin{wide} ... \end{wide}` |

## Interviews

In Claude Code, run `/ghostwriter` (or `/ghostwriter 7`, `/ghostwriter history`,
`/ghostwriter status`). The interviewer asks one source-grounded question at a
time, records answers verbatim in `interviews/sessions/`, and with your approval
works them into the chapters.

**Quotation rule:** the author is never quoted in chapter body text. Body text
paraphrases; short quotes go only in footnotes; full statements stay in
`interviews/`.

Markers in the chapter sources: `% TODO-INTERVIEW:` (a gap to fill by interview)
and `% TODO-VERIFY:` (a fact or agent-recorded statement to confirm).

## Cover

Put a portrait 2:3 image (at least 1800 x 2700 px) at `images/cover.jpg`.
Until then a solid colour stands in for it.
