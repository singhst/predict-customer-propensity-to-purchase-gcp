CREATE OR REPLACE MODEL `demo.dnn_model`
OPTIONS(MODEL_TYPE='DNN_CLASSIFIER',
        ACTIVATION_FN = 'RELU',
        BATCH_SIZE = 2048,
        DROPOUT = 0.1,
        EARLY_STOP = FALSE,
        HIDDEN_UNITS = [128, 128, 128],
        LEARN_RATE=0.001,
        MAX_ITERATIONS = 50,
        OPTIMIZER = 'ADAGRAD',
        INPUT_LABEL_COLS = ['will_buy_on_return_visit']
        )
AS
SELECT * EXCEPT (fullVisitorId, name, email, phone_number, credit_card)
FROM `demo.training_data`;