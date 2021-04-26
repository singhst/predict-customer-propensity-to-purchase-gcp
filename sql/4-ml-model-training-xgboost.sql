CREATE OR REPLACE MODEL `demo.xgboost_model`
OPTIONS(MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER',
        BOOSTER_TYPE = 'GBTREE',
        NUM_PARALLEL_TREE = 1,
        MAX_ITERATIONS = 50,
        TREE_METHOD = 'HIST',
        EARLY_STOP = FALSE,
        SUBSAMPLE = 0.85,
        INPUT_LABEL_COLS = ['will_buy_on_return_visit']
        )
AS
SELECT * EXCEPT (fullVisitorId, name, email, phone_number, credit_card)
FROM `demo.training_data`;