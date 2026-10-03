# Article Search

A small search engine for medical research articles (PubMed / MEDLINE records),
built with [MarkLogic Server](https://www.marklogic.com/) and XQuery.

You type some words, and it finds the matching articles, highlights where the
words appear, and lets you narrow the list down by author, year, or status.

## What it can do

- **Search** the full text of the articles, with matched words highlighted.
- **Filter** results with one click by author, publication year, or citation status.
  Click a filter again to remove it.
- **Sort** by relevance, newest, oldest, or article title.
- **Browse** every article, page by page, when the search box is empty.
- **Advanced search**: all words, any word, or an exact phrase; words to exclude;
  a status; and a journal title that autocompletes as you type.
- **Article page** with the journal, authors, dates, the abstract, and a link to
  the article on PubMed.

## Search tips

The search box understands a few extras:

| You type | You get |
| --- | --- |
| `heart surgery` | articles containing both words |
| `heart OR lung` | articles containing either word |
| `"heart surgery"` | articles containing that exact phrase |
| `heart -surgery` | articles about heart, but without the word surgery |
| `Author:Smith` | articles with an author named Smith |
| `Title:"Nature"` | articles from the journal called Nature |
| `Status:MEDLINE` | articles with that citation status |
| `heart sort:newest` | the same results, newest first (`relevance`, `newest`, `oldest`, `ArticleTitle`) |

## Running it

You need a recent version of [MarkLogic Server](https://www.marklogic.com/).
Everything below is done in the MarkLogic Admin page at `http://localhost:8001`.

### 1. Get the code

```bash
git clone https://github.com/AMROAMRO404/Search-engine.git
```

### 2. Create a database and load the articles

Create a database (with a forest) and load your PubMed / MEDLINE article XML
files into it, one article per document. The app reads these elements:
`ArticleTitle`, `AbstractText`, `Title` (the journal), `ISOAbbreviation`,
`Author` (`LastName`, `ForeName`), `DateCompleted`, `Language`, `PMID`, and the
`Status` attribute of `MedlineCitation`.

### 3. Add the indexes

The filters, sorting, and autocomplete need these range indexes on the database.
The collations must match exactly.

| Kind | On | Type | Collation |
| --- | --- | --- | --- |
| Element range index | `LastName` | string | `http://marklogic.com/collation/en/S1/T00BB/AS` |
| Element range index | `Title` | string | `http://marklogic.com/collation/en/S1/AS/T00BB` |
| Element range index | `ArticleTitle` | string | `http://marklogic.com/collation/en/S1/AS/T00BB` |
| Attribute range index | `Status` on `MedlineCitation` | string | `http://marklogic.com/collation/en/S1` |
| Field range index | field `neededYear` | gYear | (none) |

`neededYear` is a field you create yourself. Point it at the element that holds
the article's year (for example `Year`), then add a field range index of type
`gYear` on it.

### 4. Create the web server

Under **Groups → Default → App Servers**, create an **HTTP** server:

- **root**: the full path of the folder you cloned
- **port**: any free port, for example `8050`
- **modules**: `(file system)`
- **database**: the database from step 2

### 5. Open it

Go to `http://localhost:8050/index.xqy`.

## How the code is organised

```
index.xqy                  Main page: search box, filters, results, article page
advanced.xqy               Advanced search form
autocomplete.xqy           Returns journal title suggestions for the form
modules/
  search-config.xqy        Search settings: filters, sort orders, index names
  advanced-lib.xqy         Turns the advanced form into a search query
  layout.xqy               The page frame shared by every page
css/search.css             App styles (on top of Bulma)
js/facets.js               The "more... / less..." links in the filters
autocomplete/              Third-party autocomplete widget (Prototype, script.aculo.us)
images/                    Filter checkbox icons
```

A request goes like this:

1. `index.xqy` reads the search text, sort order, and page number from the URL.
2. It asks the MarkLogic Search API for results, using the settings in
   `modules/search-config.xqy`.
3. It turns the response into HTML: filters on the left, results on the right.

To change a filter, a year range, or a sort order, edit
`modules/search-config.xqy`; that is the only place they are defined.

## Contributors

- **Amir Altakroori** — [@AmirAltakroori](https://github.com/AmirAltakroori)
- **Amro Amro** — [@AMROAMRO404](https://github.com/AMROAMRO404)
- **Maher Issa**
