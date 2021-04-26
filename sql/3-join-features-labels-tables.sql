CREATE OR REPLACE TABLE demo.propensity_data AS
SELECT
    fullVisitorId,
    bounces,
    time_on_site,
    will_buy_on_return_visit
FROM (
        # select features
        SELECT
        fullVisitorId,
        IFNULL(totals.bounces, 0) AS bounces,
        IFNULL(totals.timeOnSite, 0) AS time_on_site
        FROM
        `demo.features`
        WHERE
        totals.newVisits = 1
        AND date BETWEEN '20160801' # train on first 9 months of data
        AND '20170430'
    )
JOIN (
        SELECT
        fullvisitorid,
        IF (
            COUNTIF (
                    totals.transactions > 0
                    AND totals.newVisits IS NULL
                    ) > 0,
            1,
            0
            ) AS will_buy_on_return_visit
        FROM
        `demo.labels`
        GROUP BY
        fullvisitorid
    )
USING (fullVisitorId)
ORDER BY time_on_site DESC;