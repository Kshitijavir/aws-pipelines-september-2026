# 🧩 06) SP Task-Based Data Load

> 📌 This file explains the idea in simple words.
> All the SQL lives in [snowflake.sql](snowflake.sql). Nothing to run from here.

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [06) SP Task-Based Data Load.md](06%29%20SP%20Task-Based%20Data%20Load.md) | This explanation |
| [snowflake.sql](snowflake.sql) | Every SQL statement for this practice, ready to paste into a Snowflake worksheet |
| [cleanup.md](cleanup.md) | Deletes everything this practice creates |

## 🎯 Goal

In the last practice we still had to type `CALL SP_LOAD_DATA();` by hand.

This time we want the SP to run **by itself**.
But only when the incoming data has **stopped coming**.

So a **Snowflake Task** will:

1. wake up **every 1 minute**
2. check if new records are still arriving
3. if nothing new arrives for **3 checks in a row** → call the SP

> **One correction to the first idea:** SP 1 should **not** "wait for 3 minutes".
> The **Task** does the waiting. The SP only runs once, at the end.

---

## 1️⃣ What We Have Currently

Our previous pipeline was:

```mermaid
flowchart LR
    ST["🗂️ STAGING"] --> SP["🧩 CALL SP_LOAD_DATA()"]
    SP --> T["🟩 CUSTOMER · PRODUCT · LOCATION<br/>PROVIDER · CLAIM"]
    SP --> SA["🟩 SP_LOAD_AUDIT"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef aud fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class ST src
    class SP sp
    class T dim
    class SA aud
```

And we had two audit tables:

```text
STAGING  →  STAGING_LOAD_AUDIT      (what came in)
SP       →  SP_LOAD_AUDIT           (what the SP loaded)
```

So the only problem left is this:

```text
New records come
       ↓
STAGING
       ↓
We manually run
CALL SP_LOAD_DATA()
       ↓
Derived tables
```

**We do not want to call the SP by hand any more.**

---

## 2️⃣ New Requirement

Now we want this:

```mermaid
flowchart TB
    N["📥 New data comes in"] --> ST["🗂️ STAGING"]
    ST --> A1["🟩 STAGING_LOAD_AUDIT<br/>records it"]
    A1 --> TK["⏰ SNOWFLAKE TASK<br/>checks every 1 minute"]
    TK --> Q{"New records<br/>still coming?"}
    Q -->|"yes"| W["⏳ keep checking"]
    Q -->|"3 checks with none"| SP["🧩 CALL SP_LOAD_DATA()"]
    SP --> T["🟩 5 target tables loaded"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:3px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef aud fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class N,ST src
    class A1 aud
    class TK,Q,W task
    class SP sp
    class T dim
```

So the Task is basically asking one question, again and again:

> **"Are new records still coming?"**

- **Yes** → keep waiting
- **No, for 3 checks in a row** → the data has settled → call the SP

---

## 3️⃣ Simple Example

Suppose Load 1 comes:

```text
10:00  →  STAGING receives 5 records
```

Then the Task checks:

```mermaid
flowchart TB
    N["📥 10:00<br/>5 records arrive"] --> C1["⏰ 10:01 · check 1<br/>no new records · count = 1"]
    C1 --> C2["⏰ 10:02 · check 2<br/>no new records · count = 2"]
    C2 --> C3["⏰ 10:03 · check 3<br/>no new records · count = 3"]
    C3 --> CALL["▶️ CALL SP_LOAD_DATA()"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    class N src
    class C1,C2,C3 task
    class CALL sp
```

Three checks with nothing new → the data is stable → **now** call the SP.

This is exactly the table our `TASK_CHECK_AUDIT` will show:

| CHECK_ID | CHECK_TIME | RECORD_COUNT | NEW_RECORD_FOUND | CONSECUTIVE_NO_DATA_COUNT | ACTION |
| --- | --- | --- | --- | --- | --- |
| 1 | 10:01 | 5 | N | 1 | WAIT |
| 2 | 10:02 | 5 | N | 2 | WAIT |
| 3 | 10:03 | 5 | N | 3 | CALL SP |

---

## 4️⃣ What If New Data Comes During the Waiting Time?

This is very important.
Suppose 5 more records arrive **in the middle** of the counting.

Then the counter goes back to **0** and we start again.

```mermaid
flowchart TB
    A["⏰ 10:01 · check · no new data · count = 1"] --> B["📥 10:02 · 5 more records arrive"]
    B --> C["⏰ 10:02 · check · NEW data found<br/>count = 0 (reset)"]
    C --> D["⏰ 10:03 · no new data · count = 1"]
    D --> E["⏰ 10:04 · no new data · count = 2"]
    E --> F["⏰ 10:05 · no new data · count = 3"]
    F --> G["▶️ CALL SP_LOAD_DATA()"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef warn fill:#fff9c4,stroke:#f9a825,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    class A,D,E,F task
    class B,C warn
    class G sp
```

So the rule is simple:

```text
New records found  →  reset the counter  →  start counting again
No new records     →  counter + 1
Counter reaches 3  →  CALL SP_LOAD_DATA()
```

---

## 5️⃣ New Complete Architecture

```mermaid
flowchart TB
    ND["📥 NEW DATA"] --> ST["🗂️ STAGING"]
    ST --> A1["🟩 STAGING_LOAD_AUDIT"]
    A1 --> TK["⏰ SNOWFLAKE TASK<br/>check every 1 minute"]
    TK --> Q{"New records?"}
    Q -->|"yes"| R["🔄 reset counter"]
    Q -->|"no"| K["➕ counter + 1"]
    R --> TK
    K --> T3{"3 in a row?"}
    T3 -->|"no"| TK
    T3 -->|"yes"| SP["🧩 CALL SP_LOAD_DATA()"]
    SP --> T1["🟩 CUSTOMER"]
    SP --> T2["🟩 PRODUCT"]
    SP --> T4["🟩 LOCATION"]
    SP --> T5["🟩 PROVIDER"]
    SP --> T6["🟩 CLAIM"]
    SP --> A2["🟩 SP_LOAD_AUDIT"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef aud fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class ND,ST src
    class TK,Q,R,K,T3 task
    class SP sp
    class A1,A2 aud
    class T1,T2,T4,T5,T6 dim
```

> 📌 A Task needs **compute** to run.
> So this practice creates its own warehouse: `TASK_LOAD_WH`.
> This is the first practice in this folder that needs one.

---

## 6️⃣ Very Important Point

We now have **three different things**, each with one job:

```mermaid
flowchart LR
    ST["🗂️ STAGING<br/>keeps the data"] --> TK["⏰ TASK<br/>checks the data"] --> SP["🧩 SP<br/>loads the data"] --> T["🟩 derived tables"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    class ST src
    class TK task
    class SP sp
    class T dim
```

| Thing | Its only job |
| ----- | ------------ |
| `STAGING` | Stores the incoming data |
| Snowflake Task | Checks whether new data is still coming |
| Stored Procedure | Loads the data into the derived tables |

**The Task does not load anything.** It only decides **when** to load.

---

## 7️⃣ Audit Table 1 — `STAGING_LOAD_AUDIT`

This is the same table as the last practice.
It records when data comes into `STAGING`.

| LOAD_ID | RECORD_COUNT | LOAD_TIME | STATUS | COMMENTS |
| --- | --- | --- | --- | --- |
| 1 | 5 | 10:00 | SUCCESS | Load 1 inserted into STAGING |
| 2 | 5 | 10:02 | SUCCESS | Load 2 inserted into STAGING |
| 3 | 5 | 10:04 | SUCCESS | Load 3 inserted into STAGING |

So we know:

```text
Load 1 → 5
Load 2 → 5
Load 3 → 5
```

---

## 8️⃣ New Audit Table — `TASK_CHECK_AUDIT`

This is the **new** table in this practice.

It answers:

> **"What did the Task check, and why did it call the SP?"**

| Column | What it holds |
| ------ | ------------- |
| `CHECK_ID` | Which check it was (1, 2, 3 …) |
| `CHECK_TIME` | When the Task checked |
| `RECORD_COUNT` | How many records were waiting |
| `NEW_RECORD_FOUND` | `Y` = more records came since the last check, `N` = none |
| `CONSECUTIVE_NO_DATA_COUNT` | How many checks in a row had nothing new |
| `ACTION` | `IDLE`, `WAIT` or `CALL SP` |
| `COMMENTS` | A short note |

Example:

| CHECK_ID | CHECK_TIME | RECORD_COUNT | NEW_RECORD_FOUND | CONSECUTIVE_NO_DATA_COUNT | ACTION |
| --- | --- | --- | --- | --- | --- |
| 1 | 10:01 | 5 | N | 1 | WAIT |
| 2 | 10:02 | 5 | N | 2 | WAIT |
| 3 | 10:03 | 5 | N | 3 | CALL SP |

Now you can clearly see **why** the SP was called.

```mermaid
flowchart LR
    TK["⏰ TASK check"] --> A["🟩 TASK_CHECK_AUDIT<br/>WAIT · WAIT · WAIT · CALL SP"]

    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef aud fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class TK task
    class A aud
```

---

## 9️⃣ SP Audit Table

Then we still have `SP_LOAD_AUDIT` from the last practice.
It tells us what happened **after** the SP started.

| RUN_ID | LOAD_ID | SOURCE_TABLE | TARGET_TABLE | SOURCE_RECORD_COUNT | TARGET_RECORD_COUNT | STATUS |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | STAGING | CUSTOMER | 5 | 5 | SUCCESS |
| 1 | 1 | STAGING | PRODUCT | 5 | 5 | SUCCESS |
| 1 | 1 | STAGING | LOCATION | 5 | 5 | SUCCESS |
| 1 | 1 | STAGING | PROVIDER | 5 | 5 | SUCCESS |
| 1 | 1 | STAGING | CLAIM | 5 | 5 | SUCCESS |

So together we get the **full story** of one load.

---

## 🔟 Full Audit Flow

```mermaid
flowchart TB
    ST["🗂️ STAGING"] --> A1["🟩 STAGING_LOAD_AUDIT<br/>what came in"]
    A1 --> TK["⏰ SNOWFLAKE TASK"]
    TK --> A2["🟩 TASK_CHECK_AUDIT<br/>what the Task checked"]
    A2 --> Q["3 checks with NO DATA"]
    Q --> SP["🧩 CALL SP_LOAD_DATA()"]
    SP --> T["🟩 CUSTOMER · PRODUCT · LOCATION<br/>PROVIDER · CLAIM"]
    SP --> A3["🟩 SP_LOAD_AUDIT<br/>what the SP loaded"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef aud fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class ST src
    class TK,Q task
    class SP sp
    class A1,A2,A3 aud
    class T dim
```

Three audit tables → three clear answers:

| Audit table | The question it answers |
| ----------- | ----------------------- |
| `STAGING_LOAD_AUDIT` | What **came in**? |
| `TASK_CHECK_AUDIT` | What did the **Task** check, and why did it call the SP? |
| `SP_LOAD_AUDIT` | What did the **SP** load? |

This is much easier to monitor when something looks wrong.

---

## 1️⃣1️⃣ What Happens With Our 6 Loads?

We still keep 6 loads × 5 records = 30 records.

Suppose all 6 loads arrive within a few minutes:

```text
Load 1 → 5
Load 2 → 5
Load 3 → 5
Load 4 → 5
Load 5 → 5
Load 6 → 5
----------------
Total    30
```

The Task keeps checking.
While new records are still arriving, the counter keeps getting reset and the Task keeps saying `WAIT`.

Once there are **3 checks in a row with nothing new**:

```mermaid
flowchart TB
    ST["🗂️ STAGING<br/>30 records waiting"] --> TK["⏰ TASK<br/>WAIT · WAIT · WAIT"]
    TK --> CALL["▶️ CALL SP_LOAD_DATA()"]
    CALL --> T["🟩 CUSTOMER 30 · PRODUCT 30 · LOCATION 30<br/>PROVIDER 30 · CLAIM 30"]
    CALL --> FLAG["✅ PROCESSED_FLAG = 'N' → 'Y'"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef ok fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class ST src
    class TK task
    class CALL sp
    class T dim
    class FLAG ok
```

The SP then processes only the rows where `PROCESSED_FLAG = 'N'` — exactly like the last practice.

---

## 1️⃣2️⃣ What Happens When Another Load Comes Later?

Suppose after the SP finishes, another **5 records** arrive.

```text
Old records = 30   →  PROCESSED_FLAG = 'Y'
New records =  5   →  PROCESSED_FLAG = 'N'
---------------------------------------
Total       = 35
```

The Task sees the new records, and waits for:

```text
no · no · no
```

for three checks.

Then:

```mermaid
flowchart TB
    ST["🗂️ STAGING<br/>35 rows<br/>30 × 'Y' · 5 × 'N'"] --> TK["⏰ TASK<br/>3 checks with nothing new"]
    TK --> CALL["▶️ CALL SP_LOAD_DATA()"]
    CALL --> SKIP["⏭️ 30 old rows already processed → SKIP"]
    CALL --> LOAD["▶️ 5 new rows → LOAD"]
    LOAD --> T["🟩 CUSTOMER +5 · PRODUCT +5 · LOCATION +5<br/>PROVIDER +5 · CLAIM +5"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef skip fill:#eceff1,stroke:#607d8b,stroke-width:2px,color:#000000
    classDef ok fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class ST src
    class TK task
    class CALL sp
    class SKIP skip
    class LOAD,T ok
```

Then `PROCESSED_FLAG` becomes `'Y'` for those 5 rows again.

So every load is handled **automatically**, and no row is loaded twice.

---

## 1️⃣3️⃣ The Complete Final Pipeline

```mermaid
flowchart TB
    ND["📥 NEW DATA"] --> ST["🗂️ STAGING<br/>LOAD_ID<br/>PROCESSED_FLAG"]
    ST --> A1["🟩 STAGING_LOAD_AUDIT"]
    A1 --> TK["⏰ SNOWFLAKE TASK<br/>every 1 minute"]
    TK --> A2["🟩 TASK_CHECK_AUDIT"]
    A2 --> Q["3 checks in a row<br/>with no new data"]
    Q --> SP["🧩 CALL SP_LOAD_DATA()"]
    SP --> T1["🟩 CUSTOMER"]
    SP --> T2["🟩 PRODUCT"]
    SP --> T3["🟩 LOCATION"]
    SP --> T4["🟩 PROVIDER"]
    SP --> T5["🟩 CLAIM"]
    SP --> A3["🟩 SP_LOAD_AUDIT"]
    A3 --> CHK["🔍 Source Count = Target Count"]
    CHK --> FLAG["✅ PROCESSED_FLAG = 'Y'"]

    classDef src fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#000000
    classDef task fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef sp fill:#ffe082,stroke:#f57f17,stroke-width:3px,color:#000000
    classDef dim fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef aud fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    class ND,ST src
    class TK,Q task
    class A1,A2,A3,CHK,FLAG aud
    class SP sp
    class T1,T2,T3,T4,T5 dim
```

---

## 1️⃣4️⃣ One Important Technical Point

There is a **more Snowflake-native option** than checking the table every minute: a **Stream + Task**.

A Stream remembers what changed in a table, and a Task can look at it:

```text
WHEN SYSTEM$STREAM_HAS_DATA('my_stream')
```

Then the Task only runs when the stream really has something.

> ⚠️ But that does **not** give us the exact rule we want here:
> **"check 3 times, one minute apart, and only after 3 quiet checks call the SP"**.
> That is a **custom waiting rule**, so we keep our own counter in `TASK_CHECK_AUDIT`.

So the learning plan is:

```mermaid
flowchart TB
    L1["🟢 LEVEL 1<br/>STAGING → SP → multiple tables"]
    L2["🟢 LEVEL 2<br/>+ audit tables"]
    L3["🔵 LEVEL 3 ← you are here<br/>+ Task · 1-minute checks · 3-in-a-row rule"]
    L4["⚪ LEVEL 4 (next)<br/>STREAM → TASK → SP → multiple tables"]

    L1 --> L2 --> L3 --> L4

    classDef done fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000000
    classDef now fill:#bbdefb,stroke:#1565c0,stroke-width:3px,color:#000000
    classDef next fill:#eceff1,stroke:#607d8b,stroke-width:2px,color:#000000
    class L1,L2 done
    class L3 now
    class L4 next
```

Doing **Stream + Task** as its own practice keeps the two ideas separate and easy to understand.

---

## 📌 What to Take Away

- A **Snowflake Task** runs SQL or calls a procedure on a **schedule** (here: every 1 minute).
- The Task does **not** load data. It only decides **when** to load.
- We keep a **counter**: no new data → `+1`; new data → reset to `0`.
- When the counter reaches **3**, the data has settled, and the Task calls the SP.
- `TASK_CHECK_AUDIT` shows **every check** and **why** the SP was called.
- Newly created Tasks are **suspended**. They only run after `ALTER TASK ... RESUME`.
- A Task needs a **warehouse** for compute — so this practice creates `TASK_LOAD_WH`.
- To try it without waiting, run the check by hand:
  `CALL SP_TASK_CHECK();` three times.
- **Remember to suspend the Task when you finish**, otherwise it keeps running every minute.
