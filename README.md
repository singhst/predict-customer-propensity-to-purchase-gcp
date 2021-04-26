# Predicting Customer Propensity to Purchase
An simple tutorial from Google Cloud Platform to build a system to predict customer propensity to purchase by using BigQuery ML and AI Platform.

We get real-world ecommerce datasets of Google Merchandise Store, so we can process the data to become training data (features + labels), train and evaluate ML models, and deploy ML models to AI Platform. 


# Introduction

We believed there are unique patterns hiddened inside the customer's web behaviours. We assume that when customers reach an ecommerce website, they are looking for something, and would like to search in the platform product engine or to filter products by clicking the sorting/filtering buttons. These hiddened patterns can be appeared in their behaviours in the web. 

Machine learning can be employed to learn which types of behaviours are more likely to purchase, and which types are less to purchase from the training data with known label (i.e. made a purchase/didn't make a purchase). Then, the trained ML model can be used to predict the propensity to purchase (i.e. classification task) of new customers by comparing their behaviours to the learned.

After getting a list of new customers with high propensity score to purchase, we can use this list to remarket them in Google Ads, which ultimately hope to re-arise their interests / remind them to buy. And hopefully, to increase amount of sales of the ecommerce platform.

## - - - 
Full tutorial can be found at [link](https://cloud.google.com/architecture/predicting-customer-propensity-to-buy).


# Architecture of System

<img src="img\system-diagram-2.png" style="zoom:50%;" />


# System Flow

[picture of how data flows]


# The Dataset

The raw dataset containing customers' behaviors (e.g. `time_on_site`, `bounces`, etc.) collected from the GA360 which connected to the web page. 

<details>
<summary>Info</summary>
<p>
<img src="img\bq-01-raw-dataset-1-labels.png" style="zoom:50%;" />
</p>
</details>

<img src="img\bq-01-raw-dataset-2-features.png" style="zoom:50%;" />


# The SQL queries in BigQuery

1. Fetch the features of ML training data from the raw data set.

    ```sql
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
    ```
    
2. Fetch the labels of ML training data from the raw data set.

    <details>
    <summary>SQL code...</summary>
    <p>

    ```sql
    # select initial features and label to feed into your model
    CREATE OR REPLACE TABLE demo.labels AS
    
    SELECT
    *
    FROM
    `bigquery-public-data.google_analytics_sample.*`
    ```
    </p>
    </details>

3. Merge two datasets, feature and label, into one training dataset.

    <details>
    <summary>SQL code...</summary>
    <p>

    ```sql
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
    ```
    </p>
    </details>

4. After prepared the training data, we can use to train 

   * Logistic Regression model

        <details>
        <summary>SQL code...</summary>
        <p>

        ```sql
        CREATE OR REPLACE MODEL `demo.logistic_model`
        OPTIONS(MODEL_TYPE = 'logistic_reg',
                labels = [ 'will_buy_on_return_visit' ]
                )
        AS
        SELECT * EXCEPT (fullVisitorId, name, email, phone_number, credit_card)
        FROM `demo.training_data`;
        ```
        </p>
        </details>

   * DNN model

        <details>
        <summary>SQL code...</summary>
        <p>

        ```sql
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
        ```

   * XGBoost

        <details>
        <summary>SQL code...</summary>
        <p>

        ```sql
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
        ```
        </p>
        </details>

5. After trained each ML model, BigQuery provides details for evaluation.
    
    P.S. The below is not a good model.
    <details>
    <summary>Screenshot...</summary>
    <p>
    <img src="img\bq-02-ml-evaluation.png" style="zoom:50%;" /> 
    </p>
    </details>

6. Batch prediction in BigQuery
    <details>
    <summary>SQL code...</summary>
    <p>
    
    ```sql
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
    ```
    </p>
    </details>

    <details>
    <summary>Screenshot...</summary>
    <p>
    <img src="img\bq-03-ml-batch-prediction.png" style="zoom:50%;" />
    </p>
    </details>


# Deploy trained ML model to AI Platform

## Export BigQuery trained model to Cloud Storage

The command line:
```
# To export BigQuery trained ML model to Cloud Storage

## Create a new Busket
$ gsutil mb 'gs://demo-bq-aiplatform-propensity-to-buy-bucket'

## Export the trained ML model in BigQuery to Cloud Stoarge
$ bq extract -m demo.logistic_model gs://demo-bq-aiplatform-propensity-to-buy-bucket/V_1
```

<details>
<summary>Screenshot...</summary>
<p>
<img src="img\gcs-02-cloud-shell-save-bq-model.png" style="zoom:50%;" />
</p>
</details>
<img src="img\gcs-01-save-bq-model.png" style="zoom:50%;" />

## In AI Platform

The command line:
```
# Create and Deploy ML model from Cloud storage to AI Platform
$ gcloud ai-platform models create logistic_model

$ gcloud ai-platform versions create --model=logistic_model V_1 --framework=tensorflow --python-version=3.7 \
--runtime-version=1.15 --origin=gs://demo-bq-aiplatform-propensity-to-buy-bucket/V_1/ \
--staging-bucket=gs://demo-bq-aiplatform-propensity-to-buy-bucket
```

<details>
<summary>Screenshot 1...</summary>
<p>
<img src="img\ai-platform-01-cloud-shell-create-model.png" style="zoom:50%;" /> 
</p>
</details>

<details>
<summary>Screenshot 2...</summary>
<p>
<img src="img\ai-platform-02-cloud-shell-deploy-model.png" style="zoom:50%;" /> 
</p>
</details>

The deployed ML model:
<img src="img\ai-platform-03-deployed-model.png" style="zoom:50%;" /> 


# [Result] Online Prediction

The command line:
```
# To request a prediction to AI platform

## Make an `.json` for online prediction
echo "{\"bounces\": 0, \"time_on_site\": 7363}" > input.json

## Request the predictions
$ gcloud ai-platform predict --model demo_trained_model --region asia-east1 --version V_1 --json-instances input.json
OR 
$ gcloud ai-platform predict --model logistic_model --region us-east4 --version V_1 --json-instances ai_platform/input.json
```

Return result:
```
PREDICTED_WILL_BUY_ON_RETURN_VISIT  WILL_BUY_ON_RETURN_VISIT_PROBS            WILL_BUY_ON_RETURN_VISIT_VALUES
['1']                               [0.661069205638202, 0.33893079436179796]  ['1', '0']
```

<img src="img\ai-platform-04-online-prediction.png" style="zoom:50%;" /> 
