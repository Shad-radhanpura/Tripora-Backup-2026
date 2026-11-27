# Tripora Documentation QA Report

Project: Tripora: AI-Powered Personalized Travel Planner
Last build: 20 October 2026. PDF and DOCX regenerated after the diagram redesign and the bibliography review.
Scope: the report in DOCX and PDF form, the two redesigned diagrams, the logo and watermark, the audit file, and this QA file.

Result in one line: the report is built and all automated and visual checks listed below pass. Two items are still open and need your decision: the diagram text size (Section 5.3) and the Word pagination check (Section 6). The report is not declared ready to print until you decide on the diagram size and open the DOCX in Word.

## 1. Deliverables

| File | Path | Status |
|---|---|---|
| Editable Word report | `D:\tripora\documentation\Tripora_MCA_Semester_3_Project_Report.docx` | Built and structure checked in the file (6 sections, 53 tables, 3 pictures, watermark header). Page count **not verified**: Word is not installed here. |
| PDF report | `D:\tripora\documentation\Tripora_MCA_Semester_3_Project_Report.pdf` (105 pages) | Built with ReportLab as a separate generation (Section 6). Checked page by page. |
| Project audit | `D:\tripora\documentation\Tripora_Project_Audit.md` | Written from the source (read-only). |
| QA report | `D:\tripora\documentation\Tripora_Documentation_QA_Report.md` | This file. |
| Use case diagram (redesigned) | `D:\tripora\documentation\assets\use_case_diagram.png` (3000 × 2200 px) | Redrawn for readability from the verified model (`build/draw_uc2.py`). |
| ER / data model diagram (redesigned) | `D:\tripora\documentation\assets\er_diagram.png` (3000 × 2200 px) | Redrawn for readability with key fields only (`build/draw_er2.py`). Full field lists are in Section 3.2. |
| Previous diagram versions | `D:\tripora\documentation\assets\previous_v2_2026-10-20\` | Backup copies of the diagrams replaced in this round. |
| Original images (backup) | `D:\tripora\documentation\assets\originals_backup_2026-10-19\` | Copies of the first versions and the logo. |
| LJK logo | `D:\tripora\documentation\assets\ljk_logo.jpg` (455 × 439 px) | Unchanged, as supplied. |
| Build sources | `D:\tripora\documentation\build\` | Drawing scripts, content files, builders, watermark, transparent diagram copies, `toc_pages.json`. |
| Project backup before this work | `D:\Tripora_Backups\before_completion_2026-10-19_11-39` | Hash-verified earlier (30,501 files, 0 mismatches). Not changed. |

Application code, Firebase configuration, Firestore rules, dependencies (except python-docx) and deployment settings were not changed by this work. The Firestore rules were not modified or deployed.

## 2. Installations and disk space

- `python-docx` 1.2.0 was installed with pip (approved). No other software was installed. ReportLab, Pillow and PyMuPDF were already present.
- LibreOffice is not installed, so the DOCX could not be converted to PDF or paginated. The PDF is therefore a separate generation.
- Free space at the start of the work: C: about 2.0 GB (critical); D: about 105 GB. All output was written to D:.

## 3. Page order and structure

| Check | Result | Evidence |
|---|---|---|
| Page 1 is the cover with the original logo in colour | Pass | PDF cover has one image (the logo) and no watermark |
| Page 2 is the certificate template | Pass | PDF page 2 contains the heading "CERTIFICATE" |
| Page 3 is the acknowledgement | Pass | PDF page 3 contains the heading "ACKNOWLEDGEMENT" |
| Page 4 is the table of contents, on one page | Pass | PDF page 4 contains "TABLE OF CONTENTS" and ends with Appendix L |
| Chapter 1 starts on physical page 5 | Pass | Contents entry "1. Introduction" = 5; the heading is on page 5 |
| Eight mandatory chapters in order | Pass | Chapters 1 to 8 in the contents and the text |
| Mandatory subsections present | Pass | 1.1–1.9; 2.1–2.3; 3.1 (with 3.1.1), 3.2, 3.3, 3.4; 4.1–4.2 with 4.3–4.6; 5.1 with 5.2–5.5; 6; 7 (with 7.1); 8 |
| Contents entries point to the right pages | Pass | 48 entries checked against the page where each heading appears: 0 mismatches |
| Footer page numbers equal the physical page number (pages 2 to 105) | Pass | Every page from 2 to 105 carries its own number |
| Appendices A to L present | Pass | A project structure; B user manual; C administrator manual; D troubleshooting; E configuration; F glossary; G diagram source; H document shapes; I destinations; J dishes; K assets; L class index |
| At least 100 PDF pages | Pass | 105 pages |
| Length of the DOCX | Not verified | Word not available |

## 4. Formatting

| Requirement | Result | Evidence |
|---|---|---|
| A4 paper | Pass (PDF); Pass (DOCX section settings) | PDF page size 595 × 842 pt; DOCX portrait 21.0 × 29.7 cm |
| Times New Roman throughout | Pass (PDF); Pass (DOCX font names) | PDF text fonts are Times New Roman (regular, bold, italic, bold italic) and Courier New for code. A Helvetica resource is listed in the PDF but no text uses it (OPEN-12). |
| Main headings 16 pt | Pass | DOCX heading 1 at 16 pt; PDF H1 at 16 pt |
| Body text 14 pt | Pass | DOCX body at 14 pt (28 half-points); PDF body at 14 pt |
| Body paragraphs justified | Pass | DOCX: 178 justified paragraphs; PDF body style is justified |
| Table text 12 pt | Disclosed deviation | Tables use 12 pt to fit the 16 cm text width. Tables are not body text. |
| Code excerpts 11 pt Courier | Disclosed deviation | Used so that code and document-shape lines fit. |
| Subsection headings 14 pt bold | Disclosed choice | The brief gave 16 pt for main headings; subsections are 14 pt bold and sub-subsections 14 pt bold italic. |
| Headers and footers | Pass (PDF); Pass (DOCX structure) | PDF: page number at the foot of every page from 2. DOCX: footer with a PAGE field from section 1. |
| No blank pages | Pass (PDF) | No near-blank portrait page. DOCX not rendered. |
| No text overlap or clipping (PDF) | Pass on sampled pages | Contents page, Table 5.1 and both diagram pages were rendered at 100 %. |
| Table widths within the 16 cm text block | Pass | Both builders scale any wider table to 16 cm (Table 5.2 and Table 6.1 were 16.6 cm and 18.0 cm). Word layout still to be checked (OPEN-5). |

## 5. Diagrams

### 5.1 Placement

| Diagram | Page | Orientation | Caption on the same page | Result |
|---|---|---|---|---|
| Figure 3.1 Use case diagram | 19 | Landscape, own page | Yes | Pass |
| Figure 3.2 ER / data model | 30 | Landscape, own page | Yes | Pass |
| Page after each diagram | 20 and 31 | Portrait | No diagram | Pass |

Each diagram is one image on one landscape page. The diagram PNGs are shown through transparent copies (pure white set to transparent) so that the watermark is visible behind them. The source diagrams in `assets` are opaque.

### 5.2 What changed in this round

Use case diagram (`draw_uc2.py`):
- Redrawn on a 3000 × 2200 px canvas with 34 px labels, arranged in five columns and groups (Account and access; Discover and plan; Packages and bookings (demo); Administration; Reviews and support).
- All 37 use cases, the three actors (Visitor, Registered User, Administrator) and the two external systems (Firebase Authentication, OpenRouter AI Service) are kept.
- Demonstration use cases have dashed outlines, device-only use cases a grey fill, implemented use cases a solid outline. A legend is included.
- The Administrator is linked only to the administration use cases. OpenRouter is linked only to Generate AI Itinerary. Firebase is linked to Sign Up, Log In and Log Out.
- Include and extend relations are shown: Log In includes Verify Administrator Role; Plan Trip includes Generate AI Itinerary; Generate Offline Itinerary extends it; Select Bus Seats extends Book Transport or Hotel; Search, Book Transport and Book Tour Package include Create Booking Request (as described in Section 3.1).

ER / data model diagram (`draw_er2.py`):
- Redrawn on a 3000 × 2200 px canvas with 36 px labels.
- Each entity lists its key fields only, to keep the text large. The complete field list with types and the source evidence is in Section 3.2, Tables 3.3 to 3.11. No field was removed from the data dictionary.
- The relationships and cardinalities are the same as in the previous version: Firebase account and users/admins (same UID); admins and admin_audit (performed by); users and trips (owns); users and favourites (has favourites, subcollection); trips and checklist (has checklist items, subcollection); users and bookings (makes); bookings and packages (refers to package, package bookings only); users and reviews (writes); reviews and the destination catalogue (about destination); favourites and the destination catalogue (refers to destination); users and support_tickets (raises); admin_audit and any document (targets).
- The support priority field is marked with a dagger, with a footnote that the active rules do not accept it.

### 5.3 Readability at 100 % zoom

Measured on the printed A4 landscape page. The landscape image is 23 cm wide (page margins 1.2 cm; the image is limited to 16.8 cm high):

| Diagram | Image width on page | Label size in the image | Printed label size | Checked at 100 % zoom |
|---|---|---|---|---|
| Use case diagram | about 22.9 cm | 34 px on a 3000 px width | about 7.4 pt | Labels legible; some connectors cross shapes (Section 5.4) |
| ER / data model diagram | about 22.9 cm | 36 px on a 3000 px width | about 7.8 pt | Attribute labels legible at 100 % (about 10 px high on screen) |

Judgement: both diagrams are now legible at 100 % zoom, with labels of about 7.4 pt (use case) and 7.8 pt (ER) printed. This is smaller than the 9 to 10 pt some reviewers prefer for diagram text, and the use case labels are the smaller of the two. The previous version printed at about 5 pt. If you want larger labels, the next step is to split the attribute detail further, which I do not recommend without your approval, because the brief keeps each diagram on one page (Section 9).

### 5.4 Remaining diagram limitations

- Use case diagram: the connectors from the Registered User cross some shapes, because the user is linked to many use cases on the other side of the diagram. Each line ends at its intended use case, but some lines pass behind other shapes.
- ER diagram: a few connector lines cross each other (for example the reviews and users connectors near the bookings box). Labels were placed in clear space and checked at 100 %.

## 6. The DOCX and PDF are separate generations

- Both files are generated from one content source (`build/content_*.py`, assembled by `build/assemble.py`).
- The PDF was produced with ReportLab, not exported from Word. Its pagination is computed independently of the DOCX.
- A comparison of the distinct words (four or more letters) in each file, from the last build before this QA, gave 1,987 words in the PDF and 1,896 in the DOCX. 99 PDF words are not in the DOCX (mostly fragments caused by PDF text extraction) and 8 DOCX words are not in the PDF. The files are **not verified to be identical**.
- The contents page of the DOCX uses the PDF page numbers. Word may paginate differently, so the DOCX contents must be updated in Word after the file is opened (OPEN-5).

## 7. Content checks

| Check | Result | Notes |
|---|---|---|
| Acknowledgement is original, with no invented names | Pass | Only placeholders and the college name |
| Certificate has no signatures, seals or approval | Pass | Blank signature and seal lines, labelled as template fields |
| Student and college placeholders are marked | Pass | `[University Name]`, `[Group Number]`, `[Course Name]`, `[Academic Year]`, `[Internal Guide Name]`, `[Guide Designation]`, `[Student Name]`, `[Enrollment Number]`, `[Roll Number]`, `[Division]`, `[Submission Date]`, `[Name and Designation]` |
| College name | From the supplied logo | "Lok Jagruti Kendra (LJK)". The university name is not on the logo and is a placeholder. |
| Features described as implemented exist in the code | Pass for the features in the audit | Each has a file reference in the audit |
| Demonstration data labelled | Pass | Chapters 1 to 4 and Appendix B state it |
| No live booking, payment or provider claim | Pass | The report states that none exists |
| Test statuses not overstated | Pass | Pass only for named tests in the last passing run (297 of 297). Rules tests, Android, browser checks and the live Firebase check are Not Executed or Blocked. |
| Dates | Pass | Commit dates from `git log`; no estimated dates given as facts |
| Figures and numbers | Pass for those checked | 35 destinations; 151 dishes; 240 packages; 95 Dart files; 23 test files; 297 tests; 530 nearby records; 36 screens; 24 services; 11 models; 9 data files |

### 7.1 Bibliography review (addresses fetched on 20 October 2026)

| Entry | Address | Check result |
|---|---|---|
| Flutter documentation | https://docs.flutter.dev | Confirmed: official Flutter documentation home page |
| Cloud Firestore data model | https://firebase.google.com/docs/firestore/data-model | Confirmed: "Cloud Firestore Data model" |
| Firestore security rules | https://firebase.google.com/docs/firestore/security/get-started | Confirmed: "Get started with Cloud Firestore Security Rules" |
| OpenRouter | https://openrouter.ai/docs/quickstart | Address changed from `/docs`, which opens the quickstart. The quickstart shows the chat completions endpoint. **The HTTP status codes cited in Section 4.1.5 (401, 429) are taken from the application code and were not confirmed against an OpenRouter reference page.** |
| Creative Commons BY-SA 4.0 | https://creativecommons.org/licenses/by-sa/4.0/ | Confirmed: the licence deed |
| UML | https://www.omg.org/spec/UML | Confirmed: "Unified Modeling Language", Version 2.5.1. The bibliography now gives the version. |
| Material Design | https://m3.material.io | The site is Material Design. The page does not confirm "version 3", so the wording is flagged in the entry. |
| Wikimedia Commons | https://commons.wikimedia.org | Confirmed: the Commons home page. The licensing page was not fetched. |
| Dart language | https://dart.dev/guides | **Not fetched.** |
| Firebase Authentication | https://firebase.google.com/docs/auth | **Not fetched.** |
| pub.dev packages | https://pub.dev | **Not fetched.** Versions are taken from `pubspec.yaml`. |
| Chen (1976), ACM Transactions on Database Systems 1(1) | no link | **Not verified.** Publication details must be checked before submission. |

## 8. Known open issues

| ID | Issue | Severity | Owner action |
|---|---|---|---|
| OPEN-1 | Diagram labels print at about 7.4 pt (use case) and 7.8 pt (ER). Legible at 100 %, but smaller than some reviewers prefer. | Medium (decision) | Accept, or ask for a further reduction in attribute detail. |
| OPEN-2 | Support tickets with the `priority` field and the new categories are refused by the repository security rules. The app saves them only to the device outbox. | High | Approve a rules change (`firestore.rules.feedback.proposed` is a candidate). Not done here. |
| OPEN-3 | The live Firebase rules were not compared with the repository copy. | High | Compare the Console text and publish time with `firestore.rules`. |
| OPEN-4 | 120 of 151 dishes have no verified photograph. | Medium | Supply licensed photos with credits. |
| OPEN-5 | The DOCX has not been paginated in Word, so its contents page numbers and table layout are unverified. | Medium | Open the DOCX in Word, update the fields, and check the page numbers. |
| OPEN-6 | Bibliography: OpenRouter error codes, Dart, Firebase Authentication, pub.dev, the Commons licensing page, Material "version 3" wording and the Chen reference are not verified. | Medium | Check the flagged items in Section 7.1 before submission. |
| OPEN-7 | Screenshots of the running application are not included. | Medium | Capture screenshots of the current build and insert them in Section 3.3. |
| OPEN-8 | The Android build and browser visual checks were not run. | Medium | Run them and record the results. |
| OPEN-9 | Student, guide and academic details are placeholders. | Required before submission | Supply the values. |
| OPEN-10 | Certificate signatures, seals and approval are not provided. | Required before submission | Obtain from the college. |
| OPEN-11 | Use case diagram connectors from the Registered User cross some shapes. | Low | Accept, or redraw the connectors with a different actor position. |
| OPEN-12 | A Helvetica font resource is listed in the PDF although no text uses it. | Low | Not investigated further; no visible effect was seen. |

## 9. Decisions needed from the owner

1. **Diagram label size.** Accept the current 7.8 pt printed size (legible at 100 %), or ask for a larger size, which needs further reduction of the attribute detail in the ER diagram.
2. **Support rules.** Approve a change to `firestore.rules` that accepts the support fields the app writes. This is a separate task; nothing has been changed or deployed.
3. **Review destinations.** Decide whether the review allow-list should cover all 35 destinations.
4. **Dish photographs.** Decide whether the 120 placeholder dishes keep placeholders.

## 10. Verification performed in this round

- Diagrams: each redrawn diagram was rendered, its labels read at full size, and its placement and caption checked on the PDF page.
- PDF: 105 pages; page size; landscape pages (19 and 30) only; no blank portrait pages; contents page accurate for 48 entries (0 mismatches); page numbers on pages 2 to 105; a watermark image on every page from 2 to 105; one image (the logo) on the cover.
- DOCX: six sections; the first section is the cover (no watermark); sections 1 to 5 inherit the watermark header, which is anchored behind the text; the page-number footer is present; fonts and sizes as stated in Section 4.
- Bibliography: six addresses fetched and confirmed; the others are flagged in Section 7.1.
- Test results: the last full run (297 of 297 passed, analyzer clean, web build successful) was not re-run in this round.

## 11. Limitations of this QA

- No Word or LibreOffice on this machine, so the DOCX was checked from its XML and was not rendered or paginated.
- No Firebase Console access, so the live rules and live data were not checked.
- No browser or Android device was used for visual checks.
- No screenshots of the running application exist yet.
- The DOCX watermark was checked in the XML, not rendered.
