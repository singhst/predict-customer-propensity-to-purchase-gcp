# select initial features and label to feed into your model

CREATE OR REPLACE TABLE demo.labels AS
SELECT
    *
FROM
    `bigquery-public-data.google_analytics_sample.*`