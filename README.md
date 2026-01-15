# credit-card-fraud-analytics
End-to-end Credit Card Fraud Analytics project using SQL Server and Power BI

# Credit Card Fraud Analytics – End-to-End SQL & Power BI Project

## 📍 Project Overview
This project is an end-to-end **Credit Card Fraud Analytics case study**, designed to simulate how financial institutions like **American Express** analyze transaction-level data to detect fraud patterns, assess customer risk, and support executive decision-making.

The project covers the complete analytics lifecycle:
- Raw data ingestion
- Data modeling in SQL Server
- Advanced SQL analysis
- Business-focused Power BI dashboards
- Executive storytelling and risk segmentation

---

## 🎯 Business Problem
Financial institutions process millions of transactions daily. Key challenges include:
- Identifying fraudulent transactions early
- Understanding fraud behavior by geography, time, and category
- Segmenting customers based on fraud risk
- Communicating insights clearly to non-technical stakeholders

This project answers questions such as:
- When does fraud most frequently occur?
- Which states and merchant categories are most vulnerable?
- Which customers pose the highest fraud risk?
- How can executives monitor fraud KPIs in real time?

---

## 🗂 Dataset Information
- Source: Public credit card transaction dataset (Kaggle)
- Size: ~1.3M transaction records
- Data Level: Transaction-level

### Key Columns:
- `cc_num` – Customer identifier
- `trans_date_trans_time` – Transaction timestamp
- `amt` – Transaction amount
- `category` – Merchant category
- `state` – Transaction state
- `is_fraud` – Fraud flag (1 = fraud, 0 = non-fraud)

⚠️ **Note**: Raw data is not uploaded to GitHub to follow best practices.

---

## 🧱 Tech Stack
- **Database**: Microsoft SQL Server (SSMS)
- **Visualization**: Power BI
- **Version Control**: Git & GitHub
- **Modeling Techniques**:
  - Window functions
  - CTEs
  - Views
  - Risk scoring logic
  - Dimensional modeling

---

## 🏗 Project Architecture



---

## 🧪 SQL Analysis Phases

### Phase 1 – Data Understanding & Cleaning
- Imported large CSV using SQL Server Import Wizard
- Handled truncation errors and datatype mismatches
- Removed unnecessary index column
- Validated fraud flag distribution

### Phase 2 – Fraud Pattern Analysis
- Fraud trends by:
  - Transaction day
  - Transaction hour
  - Merchant category
- Used aggregation and window functions
- Normalized fraud metrics to avoid misleading results

### Phase 3 – Customer Risk Segmentation
- Calculated:
  - Total spend
  - Fraud amount
  - Fraud rate
- Designed a **custom fraud risk score**
- Classified customers into:
  - High Risk
  - Medium Risk
  - Low Risk

### Phase 4 – Analytical Views
Created reusable SQL views:
- `vw_fraud_patterns`
- `vw_customer_risk`
- `vw_executive_kpis`

These views were directly consumed by Power BI.

---

## 📊 Power BI Dashboards

### 1️⃣ Executive Fraud Overview
Purpose: High-level monitoring for leadership
- KPI Cards:
  - Total Transactions
  - Total Fraud Amount
  - Fraud Rate
- Fraud trends by day (corrected weekday sorting using a Day Dimension)
- Geographic fraud distribution using Shape Maps

### 2️⃣ Fraud Pattern Analysis
Purpose: Identify behavioral fraud trends
- Fraud by merchant category
- Fraud by hour of day
- Fraud incidents per 1,000 transactions (normalized metric)

### 3️⃣ Customer Risk Segmentation
Purpose: Operational & investigation focus
- Customer-level fraud risk table
- Conditional formatting based on risk score
- Scatter plot for spend vs fraud behavior
- Clear High / Medium / Low risk classification

---

## ⚠️ Key Challenges & Solutions

### Challenge: Incorrect weekday sorting in Power BI
- Issue: Days sorted alphabetically instead of chronologically
- Solution:
  - Created a **Day Dimension table**
  - Established proper relationships
  - Used "Sort by Column" correctly

### Challenge: Large dataset import errors
- Issue: Data truncation and datatype mismatch
- Solution:
  - Adjusted column datatypes
  - Used INT instead of SMALLINT where required

### Challenge: Misleading fraud percentages
- Issue: Raw fraud counts distorted insights
- Solution:
  - Normalized metrics (fraud per 1,000 transactions)

---

## 🧠 Business Insights
- Fraud is highly time-dependent (peaks during specific hours)
- Certain merchant categories show disproportionately high fraud rates
- A small percentage of customers contribute to a large share of fraud losses
- Normalized metrics are critical for fair comparison across states

---

## 📌 Key Takeaways
- SQL is essential for scalable fraud analytics
- Data modeling decisions directly impact insight quality
- Business-ready dashboards require storytelling, not just visuals
- Fraud analytics must balance accuracy, interpretability, and actionability

---

## 🚀 Future Enhancements
- Add machine learning fraud prediction
- Real-time streaming data simulation
- Drill-through investigation dashboards
- Integration with Python for advanced analytics

---

## 👤 Author
**Abhay SInghgit **  
Aspiring Data Analyst | Fraud Analytics | SQL | Power BI  

---

## ⭐ If you find this project useful
Feel free to star ⭐ the repository or connect with me on LinkedIn.
