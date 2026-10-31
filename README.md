# Olympic Games Analysis

An end-to-end analysis of the Olympic Games from **Athens 1896 to Rio 2016**. The project combines **SQL exploratory analysis (EDA)** with an interactive **Power BI report**, and turns the results into simple insights and recommendations.

- 18 EDA questions answered with SQL
- 18 Power BI questions answered across a 5-page report
- A presentation that walks through the whole workflow

---

## Repository contents

| File | Description |
|---|---|
| `sports_analysis_EDA_answers.sql` | SQL queries for the 18 EDA questions (schema: `sportsanalysis`) |
| `sports_analysis_EDA.xlsx` | EDA results workbook: query output and insights for each question |
| `sports_analysis_report.pbix` | Power BI report (5 pages, 18 questions) |
| `Sports_Analysis_overview.pptx` | Presentation: data preparation, data model, EDA, report and recommendations |
| `images/` | Screenshots of the data model and report pages (see below) |

```
.
├── README.md
├── sports_analysis_EDA_answers.sql
├── sports_analysis_EDA.xlsx
├── sports_analysis_report.pbix
├── Sports_Analysis_overview.pptx
└── images/
```

## Dataset at a glance

| Measure | Value |
|---|---|
| Olympic Games | 51 (29 Summer, 22 Winter) |
| Sports | 66 |
| Events | 757 |
| Participants | 129K |
| Medals | 41K |
| Regions (NOCs) | 228 |
| Source tables | 11 |

The tables are grouped into six analysis areas, which keeps the breakdown MECE (mutually exclusive, collectively exhaustive):

| Analysis area | Source tables |
|---|---|
| Games | `games`, `city`, `games_city` |
| Sports | `sport`, `event`, `competitor_event` |
| Events | `event`, `sport` |
| Participants | `person`, `games_competitor` |
| Medals | `medal`, `competitor_event` |
| Regions | `noc_region`, `person_region` |

## Tools

- **PostgreSQL** for the EDA queries
- **Power BI Desktop** for the data model, DAX measures and report
- **Excel** for the EDA results
- **PowerPoint** for the presentation

## Workflow

1. **Understand** the 11 tables on Games, sports, events, athletes, medals and regions.
2. **Clean** the data.
3. **Transform** the data.
4. **Model** the data in Power BI.
5. **EDA with SQL**: answer 18 questions.
6. **Report in Power BI**: build 5 pages that answer 18 questions.

### Data cleaning

| Issue found | How it was handled |
|---|---|
| Medal value `NA` means no medal | Kept for participation counts, excluded from medal counts (`medal_name <> 'NA'`) |
| Missing height and weight stored as `0` | Excluded from averages so they do not pull the numbers down |
| Team events repeat a medal for each member | Used `COUNT(DISTINCT)` for Games, events and athletes; team medals count per member |
| Athletes can represent different countries | Took the region from `person_region` so each athlete maps to one region |
| Games with two host cities (1956) | Counted distinct Games so Stockholm and Melbourne do not double count |
| Defunct nations (Soviet Union, East Germany) | Kept as separate regions instead of merging them into modern countries |

### Data transformation

- **One fact table:** the competitor, athlete, event, sport, medal and region tables are joined into a single table (`consolidated_fact`).
- **Age Group and Age Order:** ages are grouped into Under 18, 18-24, 25-29, 30-34 and 35+. Age Order sorts the groups correctly.
- **Decade column:** `games_year` is turned into 1890s to 2010s on the `games` table.
- **Host city table:** `games_city` is merged with `city` to create `gamescity` with `city_name`.
- **DAX measures:** 16 measures, such as Total Games, Summer and Winter Games, Participants, Medals, Average Age and Countries.

## Data model

A small star-style model with `games` as the central filter table.

| Relationship | Type | Key | Purpose |
|---|---|---|---|
| `games` to Fact | One-to-many | `games_id` | One Games has many athlete-event rows, so season, year and decade slicers filter every participant and medal |
| `games` to `gamescity` | One-to-many | `games_id` | A Games can have more than one host city; feeds the Hosted cities chart |
| Fact and `gamescity` | No direct link | none | Both connect through `games`, which avoids ambiguous filter paths |

All measures are stored in the Fact table.

![Data model](images/data_model.png)

## Power BI report

| Page | Questions | What it shows |
|---|---|---|
| Olympic Overview | Q1 to Q3 | Games by season, Games by decade, hosted cities |
| Sports and Events | Q4 to Q9 | Sports by season, events by sport, events by gender, trends over time |
| Participants | Q10 to Q12 | Gender split, regions with most participants, age distribution |
| Medal Analysis | Q13 to Q15 | Medals by Games, gold by region, medals by sport |
| Regional Analysis | Q16 to Q18 | Regions per Games, participants on a map, medals by region |

Slicers across the pages include season, Games year, sport, gender and Games name.

![Olympic Overview](images/page1_overview.png)
![Sports and Events](images/page2_sports_events.png)
![Participants](images/page3_participants.png)
![Medal Analysis](images/page4_medals.png)
![Regional Analysis](images/page5_regional.png)

## EDA questions and key findings

All queries are in `sports_analysis_EDA_answers.sql`.

| # | Question | Key finding |
|---|---|---|
| 1 | Hosting frequency | 51 Games; the usual gap is 4 years, and since 1994 the Games are held every 2 years |
| 2 | Size of the Games | Summer events grew from 42 to 306; Winter from 17 to 98 |
| 3 | Notable Games | Rio 2016 had the most competitors (11,176) |
| 4 | Emerging sports | Only 4 sports added since 2000 |
| 5 | Sport popularity | Athletics is the largest Summer sport (2,268 in 2016) |
| 6 | Regional sports | No sport belongs to one region; Rugby is 39.6% French |
| 7 | Gender gap in events | Men 456 events vs women 211; biggest gap in Shooting |
| 8 | New events | 31 events introduced since 2012; 17 are women's |
| 9 | Discontinued events | 358 events no longer held |
| 10 | Height and weight | Average height about 175.9 cm and stable since 1990 |
| 11 | Dominant countries | The USA tops 8 of 35 sports; 33.7% of Swimming medals |
| 12 | Success factors | Medalists are 2.6 cm taller than non-medalists |
| 13 | Consistent performers | The USA medalled in 50 of 51 Games |
| 14 | Medals by region and sport | Same query as Q11 (Cuba leads Baseball with 33.3%) |
| 15 | Surprising medal wins | Kosovo won gold with only 8 athletes |
| 16 | Regional growth and decline | Brazil grew most from 1996 to 2016 (+243) |
| 17 | Geography and sport | 10 regions hold 71% of Winter medals |
| 18 | Impact on the medal tally | The USA leads with 5,414 medals |

## Key insights and recommendations

- **Hosting:** choose host cities from more regions. Only Athens and London have hosted 3 times.
- **Sport selection:** keep core sports, review very low-participation sports and add events that attract many regions.
- **Gender balance:** add women's and mixed events. Women have 211 events against 456 for men, and 26% of athletes.
- **Regional representation:** support regions with low participation or no medals, for example through qualification routes.

## Limitations

- Duration of the Games in days is not in the data, so event count is used as a proxy for size.
- Medals are counted per competitor, so team medals are counted once per member and inflate team sports.
- Q14 uses the same query as Q11. An event-level version would give a different view.
- Defunct nations show athletes after they dissolved, so their large declines in Q16 are a data artefact.
- Some chart values in the report insights are read from screenshots and are approximate.

## How to use

1. **Power BI:** open `sports_analysis_report.pbix` in Power BI Desktop and use the page tabs and slicers.
2. **SQL:** load the data into PostgreSQL under the schema `sportsanalysis`, then run `sports_analysis_EDA_answers.sql`.
3. **Results:** open `sports_analysis_EDA.xlsx` for the query output and insights.
4. **Walkthrough:** open `Sports_Analysis_overview.pptx` for the full story.

## Project Walkthrough
Watch the video explanation of this project: [Sports Analysis Video Explanation](https://drive.google.com/file/d/1EYeASI6ydANY6xpiN8MXW8lg08S6l3tK/view?usp=drive_link)

## Author

