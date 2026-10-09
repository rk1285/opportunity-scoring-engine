WITH base_data AS (

    SELECT *
    FROM read_csv_auto('data/raw/synthetic_seo_snow_rock_dataset_v3.csv')

    WHERE report_date BETWEEN $start_date AND $end_date
    --AND page LIKE $page_pattern

    --   AND NOT regexp_matches(
    --         lower(keyword),
    --         $brand_regex
    --   )

    --   AND NOT regexp_matches(
    --         lower(keyword),
    --         $short_brand_regex
    --   )

),

position_data AS (

    SELECT

        ROUND(average_position,0) AS rounded_position,

        ROUND(AVG(impressions),2) AS mean_impressions,

        ROUND(
            quantile_cont(impressions, 0.5),
            2
        ) AS median_impressions,

        ROUND(
            quantile_cont(impressions, 0.25),
            2
        ) AS lower_quartile_impressions,

        ROUND(
            quantile_cont(impressions, 0.75),
            2
        ) AS upper_quartile_impressions

    FROM base_data

    GROUP BY 1

),

gsc_data AS (

    SELECT

        page,

        keyword,

        ROUND(MIN(average_position),0) AS rounded_position,

        SUM(clicks) AS total_clicks,

        SUM(impressions) AS total_impressions,

        SUM(clicks)::DOUBLE
        / NULLIF(SUM(impressions),0) AS click_through_rate,

        ROUND(
            (
                SUM(clicks)::DOUBLE
                / NULLIF(SUM(impressions),0)
            ) * 100,
            2
        ) AS avg_ctr

    FROM base_data

    GROUP BY
        page,
        keyword

)

SELECT

    g.page,
    g.keyword,

    g.rounded_position,

    g.total_clicks,
    g.total_impressions,

    g.click_through_rate,
    g.avg_ctr,

    pd.mean_impressions,
    pd.median_impressions,
    pd.lower_quartile_impressions,
    pd.upper_quartile_impressions,

    --------------------------------------------------
    -- Opportunity Classification
    --------------------------------------------------

    CASE

        WHEN g.total_impressions > pd.upper_quartile_impressions
            AND g.rounded_position BETWEEN $pos_low AND $pos_high
        THEN 'Good Opportunity'

        WHEN g.total_impressions > pd.upper_quartile_impressions
            AND g.rounded_position <= $striking_pos
        THEN 'Striking Distance'

        WHEN g.total_impressions > pd.median_impressions
            AND g.rounded_position <= $improve_pos
        THEN 'Try to Improve'

        WHEN g.rounded_position < $ignore_pos
            AND g.total_impressions < pd.median_impressions
        THEN 'Ignore'

        WHEN
            (
                length(g.keyword)
                - length(replace(g.keyword,' ',''))
                + 1
            ) >= $min_words

            AND g.avg_ctr > $ctr_threshold

            AND g.rounded_position > 3

        THEN 'Long Tail Opportunity'

        ELSE 'Misc'

    END AS opportunity_summary,

    --------------------------------------------------
    -- Question Word Detection
    --------------------------------------------------

    CASE

        WHEN regexp_matches(
            lower(g.keyword),
            '\\b(how|what|when|where|why)\\b'
        )

        THEN 'Contains Question Word'

        ELSE 'No Question Word'

    END AS question_word,

    --------------------------------------------------
    -- Position Score
    --------------------------------------------------

    CASE
        WHEN g.rounded_position <= 3 THEN 0.1
        WHEN g.rounded_position <= 10 THEN 0.6
        WHEN g.rounded_position <= 20 THEN 1.0
        ELSE 0.7
    END AS position_score,

    --------------------------------------------------
    -- Impression Score
    --------------------------------------------------

    (
        g.total_impressions
        / NULLIF(pd.upper_quartile_impressions,0)
    ) AS impression_score,

    --------------------------------------------------
    -- CTR Score
    --------------------------------------------------

    g.click_through_rate AS ctr_score,

    --------------------------------------------------
    -- Long Tail Score
    --------------------------------------------------

    CASE
        WHEN
            (
                length(g.keyword)
                - length(replace(g.keyword,' ',''))
                + 1
            ) >= $min_words
        THEN 1
        ELSE 0
    END AS longtail_score,

    --------------------------------------------------
    -- Final Opportunity Score
    --------------------------------------------------

    ROUND(

        (

            (
                CASE
                    WHEN g.rounded_position <= 3 THEN 0.1
                    WHEN g.rounded_position <= 10 THEN 0.6
                    WHEN g.rounded_position <= 20 THEN 1.0
                    ELSE 0.7
                END
            ) * $w_position

            +

            (
                LEAST(
                    g.total_impressions
                    / NULLIF(pd.upper_quartile_impressions,0),
                    2
                )
            ) * $w_impression_gap

            +

            g.click_through_rate * $w_ctr

            +

            (

                CASE

                    WHEN
                        (
                            length(g.keyword)
                            - length(replace(g.keyword,' ',''))
                            + 1
                        ) >= $min_words

                    THEN 1
                    ELSE 0

                END

            ) * $w_longtail

        ),

        3

    ) AS opportunity_score

FROM gsc_data g

INNER JOIN position_data pd
    ON g.rounded_position = pd.rounded_position

ORDER BY opportunity_score DESC
