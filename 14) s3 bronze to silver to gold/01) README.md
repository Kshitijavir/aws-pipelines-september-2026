# Bronze → Silver → Gold Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [lambda_a.py](lambda_a.py) | Lambda A — copies Bronze → Silver, adds a timestamp to the file name |
| [lambda_b.py](lambda_b.py) | Lambda B — copies Silver → Gold, then writes a "finished" marker |
| [state_machine.json](state_machine.json) | The Step Functions workflow — start Lambda A, then wait for the marker |
| [trust_policy.json](trust_policy.json) | The IAM trust policy for the one shared role |
| [eventbridge_pattern_bronze.json](eventbridge_pattern_bronze.json) | The rule that starts the workflow |
| [eventbridge_pattern_silver.json](eventbridge_pattern_silver.json) | The rule that runs Lambda B |

---

# 🎯 What This Pipeline Does

**In one sentence:** you drop a file into the Bronze bucket, and it ends up in the Gold bucket inside today's date folder.

```text
You upload           It ends up here
customer_data.csv    Gold/2026/09/15/customer_data_2026-09-15_19-35-42.csv
```

**In three buckets:**

| Bucket | What it holds |
| ------ | ------------- |
| **Bronze** | The file you uploaded, untouched |
| **Silver** | The same file, with a timestamp added to its name |
| **Gold** | The file again, filed inside `Year/Month/Day/` — ready to query |

**And Step Functions watches the whole thing** so you get a clear green **SUCCEEDED** or red **FAILED** at the end.

---

# 🔗 How Everything Is Connected — 8 Connections

Read these in order. Each one only needs the one before it to make sense.

## 1️⃣ Bronze Bucket ➜ EventBridge Rule A

```text
┌───────────────┐                      ┌──────────────────────┐
│ Bronze Bucket │ ── file uploaded ──► │ EventBridge Rule A   │
└───────────────┘                      │ bronze-object-created│
                                       └──────────────────────┘
```

| | |
| --- | --- |
| **How to set it up** | Bronze bucket → **Properties** → **Event Notifications** → **Amazon EventBridge** → **ON** |
| **What travels** | the S3 event that says "a new file appeared" |
| **Why it's needed** | by itself, S3 does not call anything. Switching EventBridge ON makes S3 *announce* every upload. |

## 2️⃣ EventBridge Rule A ➜ Step Functions

```text
┌──────────────────────┐                       ┌──────────────────────────┐
│ EventBridge Rule A   │ ── start workflow ──► │ Step Functions           │
└──────────────────────┘                       │ bronze-silver-gold-workflow│
                                               └──────────────────────────┘
```

| | |
| --- | --- |
| **How to set it up** | Rule A → **Target** → AWS service → **Step Functions state machine** → `bronze-silver-gold-workflow` |
| **What travels** | the whole S3 event, unchanged |
| **Why it's needed** | Rule A decides *which* uploads matter. Only uploads to Bronze pass through. Uploads to Silver or Gold do not. |

## 3️⃣ Step Functions ➜ Lambda A

```text
┌─────────────────┐                    ┌──────────────┐
│ Step Functions  │ ── invoke ───────► │ Lambda A     │
└─────────────────┘                    │ bronze-to-silver│
                                       └──────────────┘
```

| | |
| --- | --- |
| **How to set it up** | in `state_machine.json`, the `Start Lambda A` state. Replace `YOUR LAMBDA A ARN` with the real ARN |
| **What travels** | the S3 event (`Payload.$: "$"` forwards it whole) |
| **Why it's needed** | Lambda A is the only Lambda Step Functions calls directly — so **this is the only Lambda ARN that appears in the state machine.** |

## 4️⃣ Lambda A ➜ Silver Bucket

```text
┌──────────────┐                        ┌───────────────┐
│ Lambda A     │ ── copy the file ────► │ Silver Bucket │
└──────────────┘    + add timestamp     └───────────────┘
```

| | |
| --- | --- |
| **How to set it up** | `SILVER_BUCKET` at the top of `lambda_a.py` |
| **What travels** | the file itself |
| **Why it's needed** | this is hop 1 of the copy. The name becomes `customer_data_2026-09-15_19-35-42.csv`. |

> 📌 **Lambda A also returns one extra thing** — not the file, just a *name*: the name of the marker it expects Lambda B to create later. Step Functions holds on to that name. More about it in connection 8.

## 5️⃣ Silver Bucket ➜ EventBridge Rule B

```text
┌───────────────┐                      ┌──────────────────────┐
│ Silver Bucket │ ── file uploaded ──► │ EventBridge Rule B   │
└───────────────┘                      │ silver-object-created│
                                       └──────────────────────┘
```

| | |
| --- | --- |
| **How to set it up** | Silver bucket → **Properties** → **Event Notifications** → **Amazon EventBridge** → **ON** |
| **What travels** | the S3 event for the file Lambda A just wrote |
| **Why it's needed** | **this is the turning point of the whole pipeline.** Step Functions is *not* involved here. The file appearing in Silver is what starts hop 2 — not the workflow. |

> ⚠️ **Gold must NOT have EventBridge turned on.** If it did, the marker Lambda B writes would fire an event and the pipeline would trigger itself forever.

## 6️⃣ EventBridge Rule B ➜ Lambda B

```text
┌──────────────────────┐                    ┌──────────────┐
│ EventBridge Rule B   │ ── run lambda ───► │ Lambda B     │
└──────────────────────┘                    │ silver-to-gold│
                                            └──────────────┘
```

| | |
| --- | --- |
| **How to set it up** | Rule B → **Target** → AWS service → **Lambda function** → `silver-to-gold` |
| **What travels** | the S3 event for the file in Silver |
| **Why it's needed** | Lambda B's ARN belongs **here**, in the EventBridge rule — not in the state machine. Step Functions never calls Lambda B. |

## 7️⃣ Lambda B ➜ Gold Bucket (the actual file)

```text
┌──────────────┐                       ┌────────────────────────────────────┐
│ Lambda B     │ ── copy the file ───► │ Gold Bucket                        │
└──────────────┘                       │ 2026/09/15/customer_data_...csv    │
                                       └────────────────────────────────────┘
```

| | |
| --- | --- |
| **How to set it up** | `GOLD_BUCKET` at the top of `lambda_b.py` |
| **What travels** | the file, into `Year/Month/Day/` |
| **Why it's needed** | this is hop 2 — the file reaches its final home |

## 8️⃣ Lambda B ➜ Gold Bucket (the marker) ➜ back to Step Functions

```text
┌──────────────┐                    ┌─────────────────────┐
│ Lambda B     │ ── writes ───────► │ Gold Bucket         │
└──────────────┘   _status/..._SUCCESS                    │
                                       └─────────────────────┘
                                                 ▲
                                                 │ keeps checking
                                                 │
                                       ┌─────────────────────┐
                                       │ Step Functions      │
                                       │ (waiting)           │
                                       └─────────────────────┘
```

| | |
| --- | --- |
| **How to set it up** | nothing to configure — it's in the code |
| **What travels** | a tiny empty file whose *name* is the message |
| **Why it's needed** | **this is how Step Functions finds out the job is done** — explained next |

---

# 💡 The One Clever Bit: The Success Marker

**The problem.** Step Functions calls Lambda A, so it knows when Lambda A finishes. But it does **not** call Lambda B — EventBridge does. So when Lambda B finishes, Step Functions has no way to know. It is just sitting there.

**The solution.** The two never talk. Instead they **agree on a file name in advance.**

```text
Step Functions                     Lambda B
      │                                  │
      │ Lambda A told it to              │
      │ watch for this name:             │
      │                                  │
      │  _status/customer_data_          │
      │  2026-09-15_19-35-42.csv_SUCCESS │
      │                                  │
      │ checks Gold for it ──────────►   │ after copying,
      │   ...not there yet...            │ creates that
      │   ...not there yet...            │ exact file
      │                                  │
      │ ◄────── now it's there ──────────┘
      │
      ▼
  SUCCEEDED ✅
```

Step Functions keeps checking every 20 seconds. The moment the file exists, it declares success. If it never appears, the workflow fails after about 5 minutes with a clear message.

### 🔑 Why the marker name has a timestamp in it

This one detail stops a nasty bug.

Lambda A names the marker after the file **it** wrote to Silver — and that name has a timestamp:

```text
_status/customer_data_2026-09-15_19-35-42.csv_SUCCESS
```

The timestamp makes each run's marker **unique**.

Now imagine the marker were named after the original file instead — `_status/customer_data.csv_SUCCESS`. You upload `customer_data.csv` on Monday. It works. The marker stays there forever. On Tuesday you upload `customer_data.csv` again — Step Functions looks, finds **Monday's** marker still sitting there, and says **SUCCEEDED immediately** — before Lambda B has copied anything.

With the timestamp, that cannot happen.

> 🎁 **A bonus:** markers are never deleted, so `_status/` ends up as a history of every file the pipeline has ever processed.

---

# 📤 What Happens When You Upload a File

Step by step, in plain words.

```text
1.  You upload customer_data.csv to Bronze.
        ↓
2.  S3 announces it (EventBridge is ON on Bronze).
        ↓
3.  Rule A matches it, and starts Step Functions.
        ↓
4.  Step Functions creates the folder _status/ in Gold.
        ↓
5.  Step Functions calls Lambda A.
        ↓
6.  Lambda A copies the file to Silver, renaming it:
        customer_data_2026-09-15_19-35-42.csv
        ↓
7.  Lambda A tells Step Functions: "watch for
        _status/customer_data_2026-09-15_19-35-42.csv_SUCCESS"
        ↓
8.  Step Functions starts checking Gold for that file. Not there yet.
        ↓
9.  Meanwhile — the new file in Silver announces itself (EventBridge is ON on Silver).
        ↓
10. Rule B matches it, and runs Lambda B.
        ↓
11. Lambda B copies the file to Gold inside today's date folder:
        2026/09/15/customer_data_2026-09-15_19-35-42.csv
        ↓
12. Lambda B writes the marker:
        _status/customer_data_2026-09-15_19-35-42.csv_SUCCESS
        ↓
13. Step Functions' next check finds it.
        ↓
14. SUCCEEDED ✅
```

### Final result

```text
kshitij-gold-bucket
│
├── 2026/
│   └── 09/
│       └── 15/
│           └── customer_data_2026-09-15_19-35-42.csv      ← the file
│
└── _status/
    └── customer_data_2026-09-15_19-35-42.csv_SUCCESS      ← the marker
```

---

# 🏗️ Setting It Up

## Step 1: IAM Role

One role is shared by EventBridge, Step Functions, both Lambdas.

1. **IAM** → **Roles** → **Create role** → **AWS service** → **Lambda**
2. Name it `Bronze-Silver-Gold-Role`
3. Replace its **trust policy** with [trust_policy.json](trust_policy.json)

| Service in the trust policy | Why |
| --------------------------- | --- |
| `events.amazonaws.com` | both EventBridge rules |
| `states.amazonaws.com` | Step Functions |
| `lambda.amazonaws.com` | both Lambdas |

4. Attach these **managed policies**:

```text
AWSLambdaBasicExecutionRole    → Lambdas can write CloudWatch logs
AWSLambdaRole                  → EventBridge can run Lambda B
AmazonS3FullAccess             → read Bronze/Silver, write Silver/Gold
AWSStepFunctionsFullAccess     → EventBridge can start the workflow
```

## Step 2: Create Three Buckets

| Bucket | Example name |
| ------ | ------------ |
| Bronze | `kshitij-bronze-bucket` |
| Silver | `kshitij-silver-bucket` |
| Gold | `kshitij-gold-bucket` |

## Step 3: Turn EventBridge ON — but only on two of them

| Bucket | EventBridge |
| ------ | ----------- |
| Bronze | ✅ **ON** |
| Silver | ✅ **ON** |
| Gold | ❌ **OFF** — leave it off |

To turn it on: bucket → **Properties** → **Event Notifications** → **Amazon EventBridge** → **Edit** → **ON** → **Save**.

## Step 4: Create the Two Lambdas

| | Lambda A | Lambda B |
| --- | --- | --- |
| Function name | `bronze-to-silver` | `silver-to-gold` |
| Runtime | Python 3.x | Python 3.x |
| Role | `Bronze-Silver-Gold-Role` | `Bronze-Silver-Gold-Role` |
| Code | [lambda_a.py](lambda_a.py) | [lambda_b.py](lambda_b.py) |
| Change this line | `SILVER_BUCKET` | `GOLD_BUCKET` |

Both times: **Create function** → paste the code → change the bucket name → **Deploy**.

## Step 5: Create the Step Functions State Machine

1. **Step Functions** → **State machines** → **Create state machine**
2. Choose **Write workflow in code**
3. Name: `bronze-silver-gold-workflow`
4. Type: **Standard**
5. Permissions: **Use an existing role** → `Bronze-Silver-Gold-Role`
6. Paste [state_machine.json](state_machine.json)
7. Replace these placeholders:

| Placeholder | Replace with |
| ----------- | ------------ |
| `YOUR GOLD BUCKET` | your Gold bucket name — **it appears twice** |
| `YOUR LAMBDA A ARN` | Lambda A's ARN |

> ⚠️ There is **no Lambda B ARN** here, and that is correct. Lambda B is called by EventBridge, not by Step Functions.

## Step 6: Create EventBridge Rule A (Bronze → workflow)

1. **EventBridge** → **Rules** → **Create rule**
2. Name: `bronze-object-created`
3. Event bus: **default**
4. Rule type: **Rule with an event pattern**
5. Paste [eventbridge_pattern_bronze.json](eventbridge_pattern_bronze.json) → replace `YOUR BRONZE BUCKET`
6. **Target:** AWS service → **Step Functions state machine** → `bronze-silver-gold-workflow`

## Step 7: Create EventBridge Rule B (Silver → Lambda B)

1. **EventBridge** → **Rules** → **Create rule**
2. Name: `silver-object-created`
3. Event bus: **default**
4. Rule type: **Rule with an event pattern**
5. Paste [eventbridge_pattern_silver.json](eventbridge_pattern_silver.json) → replace `YOUR SILVER BUCKET`
6. **Target:** AWS service → **Lambda function** → `silver-to-gold`

---

# 🧪 Testing It

Upload any file to the **Bronze** bucket.

Then check:

| Where | What to look for |
| ----- | ---------------- |
| **Step Functions** → `bronze-silver-gold-workflow` → Executions | a **green** Succeeded |
| **Silver bucket** | `customer_data_2026-09-15_19-35-42.csv` |
| **Gold bucket** | `2026/09/15/customer_data_2026-09-15_19-35-42.csv` |
| **Gold bucket** `_status/` | `customer_data_2026-09-15_19-35-42.csv_SUCCESS` |
| **Lambda A logs** | `bronze-to-silver` → Monitor → View CloudWatch logs |
| **Lambda B logs** | `silver-to-gold` → Monitor → View CloudWatch logs |

### 🧪 Seeing the failure path

Turn **off** Rule B (`silver-object-created`), then upload a file.

Lambda A still works, and Step Functions still starts checking. But the marker never arrives. After about 5 minutes the execution goes **red**:

```text
Error : SuccessMarkerNotFound
Cause : Lambda B never wrote its success marker to the Gold bucket.
```

That is exactly right — a broken second hop shows up as a **failed workflow**, not a silent success. Turn Rule B back on afterwards.

---

# ❓ Common Questions

**Why can't Step Functions just call Lambda B too?**
It could — and then this would be a much simpler pipeline. But then it would not be event-driven. Your design says the file appearing in **Silver** is what triggers the next hop, which is how real data pipelines chain: each layer reacts to the one before it. The price is that Step Functions loses sight of it, which is what the marker solves.

**Why does Step Functions create `_status/` if Lambda B is the one writing the marker?**
So the folder exists and is obvious from the start. Lambda B drops files into it. It's a visible "this pipeline is running" signal.

**What if I upload the same file name twice?**
Fine. The timestamp in the name makes each run unique, so each run gets its own marker. Both make it to Gold. The second one does not overwrite the first.

**Does the file type matter?**
No. `.csv`, `.xlsx`, `.pdf`, or no extension at all all work. Nothing in either Lambda names a file extension — `os.path.splitext` splits whatever arrives.

---

# 🧩 Quick Reference

| # | Connection | Set up where |
| - | ---------- | ------------ |
| 1 | Bronze ➜ Rule A | EventBridge ON, on Bronze |
| 2 | Rule A ➜ Step Functions | Rule A's target |
| 3 | Step Functions ➜ Lambda A | `state_machine.json` (`YOUR LAMBDA A ARN`) |
| 4 | Lambda A ➜ Silver | `SILVER_BUCKET` in `lambda_a.py` |
| 5 | Silver ➜ Rule B | EventBridge ON, on Silver |
| 6 | Rule B ➜ Lambda B | Rule B's target |
| 7 | Lambda B ➜ Gold | `GOLD_BUCKET` in `lambda_b.py` |
| 8 | Lambda B ➜ marker ➜ Step Functions | automatic, in the code |

---

# Summary

```text
Bronze ──► Rule A ──► Step Functions ──► Lambda A ──► Silver
                            │                           │
                            │                           ▼
                            │                        Rule B
                            │                           │
                            │                           ▼
                            └────── marker ◄────── Lambda B ──► Gold
```

| Piece | Job |
| ----- | --- |
| **Bronze** | holds your upload |
| **Rule A** | notices new files in Bronze, starts the workflow |
| **Step Functions** | calls Lambda A, then waits for the marker |
| **Lambda A** | copies Bronze → Silver with a timestamp |
| **Silver** | holds the timestamped file, announces it |
| **Rule B** | notices new files in Silver, runs Lambda B |
| **Lambda B** | copies Silver → Gold, then writes the marker |
| **Gold** | holds `Year/Month/Day/file` and the `_status/` markers |

> **The idea in one line:** three buckets and two copies, where the middle hop is triggered by the bucket itself — so the workflow watches for a marker file instead of calling the second Lambda.
