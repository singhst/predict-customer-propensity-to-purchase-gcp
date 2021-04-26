# predict the inputs (rows) from the input table
SELECT
    fullVisitorId,
    predicted_will_buy_on_return_visit
FROM ML.PREDICT(MODEL demo.logistic_model,
(
    SELECT
    fullVisitorId,
    bounces,
    time_on_site
    from demo.propensity_data
))