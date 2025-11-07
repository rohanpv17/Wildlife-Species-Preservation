# **Wildlife Preservation Dashboard (DBMS Mini Project)**

This is a full-stack DBMS project built for a university course. This application provides a complete system for managing wildlife conservation data, featuring a robust MySQL backend and an interactive web dashboard built with Streamlit (Python).

The system manages complex relationships between species, preserves, environmental data, conservation plans, and real-time field observations. It uses advanced SQL features like stored procedures, functions, and triggers to enforce data integrity and automate business logic.

## **🚀 Technology Stack**

* **Frontend:** Streamlit (Python)  
* **Backend:** MySQL  
* **Database Driver:** mysql-connector-python  
* **Data Manipulation:** pandas  
* **Geolocation:** geopy (for searching and validating custom locations)

## **✨ Key Features**

### **Backend (MySQL)**

* **Relational Schema:** A fully normalized database linking species, preserves, observations, and conservation plans.  
* **Stored Procedures:**  
  * sp\_GetPreserveDashboard: A single, powerful procedure that aggregates all data for the main dashboard (details, species list, environmental data, and top species).  
  * sp\_AddNewObservation: A transaction-safe procedure (using COMMIT and ROLLBACK) to add a new observation, linking it to both a species and (optionally) a preserve.  
  * sp\_AssignSpeciesToPlan: Manages the M:N (many-to-many) relationship between species and conservation plans.  
* **SQL Functions:**  
  * fn\_GetProjectDurationDays: Calculates the duration of a conservation plan.  
  * fn\_GetSpeciesCountInPreserve: Counts the primary species linked to a preserve.  
  * fn\_GetLastObservationDate: Finds the most recent sighting for a species.  
* **Database Triggers:**  
  * trg\_ValidateProjectDates: **Prevents** bad data by ensuring a project's end date is after its start date.  
  * trg\_AlertOnCriticalEnvData: **Logs** critical environmental events (like bad air/water quality) to a separate Alerts table.

### **Frontend (Streamlit UI)**

* **Multi-Page App:** Uses a clean, tabbed interface (Dashboard, Add Data, Reports, Raw Data).  
* **Interactive Dashboard:** A dynamic dashboard that updates based on the selected preserve by calling the sp\_GetPreserveDashboard procedure.  
* **Complex Data Entry Forms:**  
  * **Hybrid Observation Form:** Allows users to log an observation either at a **"Registered Preserve"** (from a dropdown) or at a **"New/Custom Location"** (using a live geopy search-and-select).  
  * **Dynamic Species Entry:** Lets the user either select an existing species or add a new species to the database, all within the same transaction.  
* **Live Reports:** A "Reports & Statistics" tab that directly calls and displays the results from the SQL functions.  
* **Trigger Testing:** UI forms designed to intentionally test and demonstrate the database triggers (e.g., a form to add a plan with a bad date or environmental data with bad air quality).

## **🛠️ Setup and Installation**

### 1. Clone the Repository
```bash
git clone https://github.com/rohanpv17/Wildlife-Species-Preservation.git
cd Wildlife-Species-Preservation
```

### 2. Install Python Dependencies  
Make sure you have Python 3.8+ installed. Then, install the required libraries:
```bash
pip install streamlit mysql-connector-python pandas geopy
```
### 3. **Set Up the MySQL Database**  
   * Ensure you have a local MySQL server running (e.g., via MySQL Workbench).  
   * Run the complete SQL script (the one we finalized with ALTER TABLE, UPDATE, and all CREATE PROCEDURE/FUNCTION/TRIGGER commands) to create the wild\_db database, all tables, and all SQL logic.  
### 4. **Update Database Credentials**  
   * In app.py, find the init\_connection function.  
   * Update the password field to match your local MySQL root password.
```bash
connection \= mysql.connector.connect(  
    host="localhost",  
    user="root",  
    password="YOUR\_PASSWORD\_HERE",  \# \<--- UPDATE THIS  
    database="wild\_db"  
)
```
## **🏃‍♂️ How to Run the Application**

1. Open your terminal.  
2. Navigate to the project folder.
   ```bash
   cd path/to/Wildlife-Species-Preservation
   ```

3. Run the Streamlit app.
   ```bash 
   streamlit run app.py
   ```

4. Your browser will automatically open to the dashboard.

## **👤 Authors**

* **Rohan P Varghese** ([@rohanpv17](https://www.google.com/search?q=https://github.com/rohanpv17))  
* **Yuvakumar S.P.** ([@yuvakumar1234](https://www.google.com/search?q=https://github.com/yuvakumar1234))  
