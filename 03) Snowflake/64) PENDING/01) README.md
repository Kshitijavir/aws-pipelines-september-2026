# S3 → EventBridge → Step Functions → Snowflake SP1 → SP2 Pipeline

## 1. File Arrival in S3

- A CSV file is uploaded to a specific **S3 bucket/prefix**.
- The S3 event is captured by **Amazon EventBridge**.
- EventBridge triggers the **AWS Step Functions** state machine.

---

## 2. Step Functions Starts SP1

Inside Step Functions:

### Step 1 — Start SP1

- Step Functions invokes **Lambda 1**.
- Lambda 1 connects to Snowflake and calls **Stored Procedure 1 (SP1)**.
- SP1 starts the initial data-loading process.
- SP1 is executed **asynchronously**.
- Lambda 1 captures the **Snowflake Query ID** generated for SP1.
- Lambda returns the Query ID back to Step Functions.

```text
S3
 │
 ▼
EventBridge
 │
 ▼
Step Functions
 │
 ▼
Lambda 1
 │
 └──► Call SP1 (Async)
          │
          └──► Query ID
```

---

## 3. Wait for SP1

- Step Functions enters a **Wait State for 3 minutes**.
- This gives SP1 time to process the data.

```text
Lambda 1
   │
   ▼
Wait 3 Minutes
```

---

## 4. Monitor SP1 Status

After 3 minutes:

- Step Functions invokes **Lambda 2**.
- Lambda 2 uses the **Query ID** received from Lambda 1.
- It checks Snowflake query history/status to determine whether SP1 is:

  - `RUNNING`
  - `SUCCESS`
  - `FAILURE`

### If SP1 is still RUNNING

- Lambda logs the current status.
- Lambda returns `RUNNING` to Step Functions.
- Step Functions waits another **3 minutes**.
- After the wait, Step Functions invokes Lambda 2 again.

```text
        ┌───────────────┐
        │ Check SP1     │
        │ using Query ID│
        └───────┬───────┘
                │
        ┌───────┼────────┐
        ▼       ▼        ▼
     RUNNING  SUCCESS  FAILURE
        │       │        │
        ▼       ▼        ▼
   Wait 3 min  SP2    Failure
        │
        └──► Check Again
```

---

## 5. SP1 Success

When Lambda 2 detects:

```text
SP1 = SUCCESS
```

then:

- Lambda logs the successful completion.
- SP1's processing/audit information is already recorded in the **Audit Table 1**.
- Lambda returns `SUCCESS` to Step Functions.

Step Functions then proceeds to the next state.

---

## 6. Execute SP2

Step Functions invokes **Lambda 3**.

Lambda 3 calls **Stored Procedure 2 (SP2)**.

SP2 performs the main transformation/loading process:

```text
STAGING TABLE
      │
      ▼
     SP2
      │
      ├──► FACT TABLE
      │
      ├──► DIMENSION TABLES
      │
      └──► AUDIT TABLE 2
```

SP2:

- Reads data from the staging table.
- Performs required transformations/business logic.
- Loads the appropriate **dimension tables**.
- Loads the **fact table**.
- Performs required validations/checks.
- Records processing information in **Audit Table 2**.
- Returns the final processing status.

---

## 7. SP2 Completion

After SP2 completes:

- Lambda 3 receives the SP2 execution result.
- Lambda logs the result.
- Lambda passes the status back to Step Functions.

For example:

```text
SP2 = SUCCESS
```

or

```text
SP2 = FAILURE
```

---

## 8. Email Notification

Step Functions evaluates the final status.

### SUCCESS

If SP2 completed successfully:

```text
Step Functions
      │
      ▼
Email Notification Lambda
      │
      ▼
SES
      │
      ▼
User
```

The user receives a **SUCCESS email**.

### FAILURE

If SP1 or SP2 fails:

```text
Step Functions
      │
      ▼
Email Notification Lambda
      │
      ▼
SES
      │
      ▼
User
```

The user receives a **FAILURE email** containing the relevant error/status information.

---

## Complete End-to-End Architecture

```text
┌─────────────┐
│     S3      │
│  CSV Upload │
└──────┬──────┘
       │
       ▼
┌───────────────┐
│  EventBridge  │
└──────┬────────┘
       │
       ▼
┌─────────────────────────┐
│     Step Functions      │
└───────────┬─────────────┘
            │
            ▼
      ┌────────────┐
      │  Lambda 1  │
      └─────┬──────┘
            │
            │ Call SP1 Async
            ▼
      ┌────────────┐
      │    SP1     │
      └─────┬──────┘
            │
            │ Query ID
            ▼
      ┌────────────┐
      │ Wait 3 Min │
      └─────┬──────┘
            │
            ▼
      ┌────────────┐
      │  Lambda 2  │
      │ Check SP1  │
      └─────┬──────┘
            │
       ┌────┼─────────┐
       │    │         │
       ▼    ▼         ▼
   RUNNING SUCCESS   FAILURE
       │    │         │
       │    ▼         ▼
       │   SP2      Failure
       │    │
       │    ▼
       │  Lambda 3
       │    │
       │    ▼
       │   SP2
       │    │
       │    ├────► DIM TABLES
       │    ├────► FACT TABLE
       │    └────► AUDIT TABLE 2
       │
       └──► Wait 3 Min
              │
              └──► Check SP1 Again

             SUCCESS / FAILURE
                    │
                    ▼
          ┌───────────────────┐
          │ Email Lambda      │
          └─────────┬─────────┘
                    │
                    ▼
                  SES
                    │
                    ▼
              ┌──────────┐
              │  USER    │
              │ SUCCESS/ │
              │ FAILURE  │
              └──────────┘
```

---

## In One Sentence

**S3 receives the file → EventBridge triggers Step Functions → Lambda asynchronously starts SP1 and captures its Query ID → Step Functions waits 3 minutes and repeatedly checks SP1 using the Query ID → after SP1 succeeds, SP2 loads the Fact/Dimension tables and Audit Table 2 → the final status is returned to Step Functions → an Email Lambda sends SUCCESS or FAILURE notification through SES.**
