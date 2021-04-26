CREATE OR REPLACE MODEL `demo.logistic_model`
OPTIONS(MODEL_TYPE = 'logistic_reg',
        labels = [ 'will_buy_on_return_visit' ]
        )
AS
SELECT * EXCEPT (fullVisitorId, name, email, phone_number, credit_card)
FROM `demo.training_data`;