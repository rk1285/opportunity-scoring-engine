# Opportunity Scoring Engine
A weighted scoring model which identifies the highest return SEO opportunities from (synthetic) Google Search Console data.

## Project Goal
Finding pages to place focused effort on for optimisation can be time consuming especially on sites of large scale. The goal of this project was to find a way statistics can be applied at scale to surface opportunities for optimisation. Reducing manual effort and creating high quality efficient methodology are the key indicators of success.

## Methodology
Aggregations of the data early on in the script show the volume of impressions per each average position. This is used as a reference to be applied against the remainder of the data to classify pages/terms that are showing higher/lower numbers of impressions relative to what is represented in the overall data. To take a hypothetical scenario, if the upper quartile of impressions for position 3 across the whole dataset is 1000, the expectation that terms with a volume of impressions greater than the upper quartile signals a good opportunity. Impression performance alongside configurable upper/lower position bounds are used to place terms into Opportunity Score classifications in the output. 

The logic also include classification for terms that are questions or longer sentences that may indicate an opportunity to create or edit content. The idea is that the scoring model can surface both commercial opportunities for product or high purhcase intent category pages as well as informational / more long form content.

## Skills demonstrated
 SQL
 - CTE - used to pre-aggregate data such as the position based performance for impressions and position across the whole dataset.
 - SELECT, WHERE - specify the data selected and base level of filtering.
 - CASE WHEN - used for implementing the classification logic on the dataset to enable easy identification of opportunity categories.
 - GROUP BY - data aggregation
Base Statistics
 - Mean, lower / upper quartile - used to provide data benchmarks that are applied to the synthetic dataset.
