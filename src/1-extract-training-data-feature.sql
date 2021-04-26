# select initial features and label to feed into your model

CREATE OR REPLACE TABLE demo.features AS
SELECT
    *
FROM
    `data-to-insights.ecommerce.web_analytics`
WHERE
    totals.newVisits = 1
  AND date BETWEEN '20160801' # train on first 9 months of data
  AND '20170430'  