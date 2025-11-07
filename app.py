import streamlit as st
import mysql.connector
import pandas as pd
from datetime import date 
from geopy.geocoders import Nominatim  
from geopy.exc import GeocoderTimedOut, GeocoderUnavailable

# -----------------------------------------------------
# Database Connection
# -----------------------------------------------------
@st.cache_resource  # Cache the connection
def init_connection():
    """Establishes a connection to the MySQL database."""
    try:
        connection = mysql.connector.connect(
            host="localhost",
            user="root",
            password="pokerface@456",  # <--- UPDATE THIS
            database="wild_db"
        )
        return connection
    except mysql.connector.Error as e:
        st.error(f"Error connecting to database: {e}")
        return None

# Helper function to run a simple query and return a DataFrame
@st.cache_data(ttl=60) # Cache for 1 minute
def run_query(query):
    try:
        conn = init_connection()
        df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        st.error(f"Error running query '{query}': {e}")
        return pd.DataFrame()

# -----------------------------------------------------
# Page Setup
# -----------------------------------------------------
st.set_page_config(
    page_title="Wildlife Preservation Dashboard",
    page_icon="🐾",
    layout="wide"
)

st.title("🐾 Wildlife Preservation Dashboard")

conn = init_connection()

if not conn:
    st.warning("Could not connect to the database. Please check connection details.")
    st.stop()

# -----------------------------------------------------
# Create Tabs for Navigation
# -----------------------------------------------------
tab_dashboard, tab_add_data, tab_reports, tab_raw_data = st.tabs(
    ["Preserve Dashboard", "Add Data", "Reports & Statistics", "Raw Data Tables"]
)


# -----------------------------------------------------
# TAB 1: PRESERVE DASHBOARD
# -----------------------------------------------------
with tab_dashboard:
    st.header("Preserve Dashboard")
    st.write("Select a preserve to view its detailed dashboard (uses `sp_GetPreserveDashboard`).")

    try:
        preserve_list_df = run_query("SELECT P_ID, PNAME FROM species_preserves")
        if not preserve_list_df.empty:
            options = preserve_list_df['P_ID'] + " - " + preserve_list_df['PNAME']
            selected_option = st.selectbox("Choose a Preserve:", options)
            selected_pid = selected_option.split(" - ")[0]

            if st.button("Load Dashboard"):
                st.subheader(f"Dashboard for {selected_option}")
                cursor = conn.cursor(dictionary=True)
                # This procedure is now 100% accurate
                cursor.callproc('sp_GetPreserveDashboard', [selected_pid])
                
                results = []
                for result in cursor.stored_results():
                    results.append(result.fetchall())
                
                if len(results) >= 4:
                    st.markdown("#### 1. Preserve Details")
                    st.dataframe(pd.DataFrame(results[0])) # Result 1: Details
                    
                    st.markdown("---") 
                    
                    st.markdown("#### 2. Top Species by Observation")
                    top_species_df = pd.DataFrame(results[3]) # Result 4
                    
                    if not top_species_df.empty:
                        st.metric(
                            label="Most Observed Species", 
                            value=top_species_df['SP_NAME'].iloc[0], 
                            delta=f"{top_species_df['ObservationCount'].iloc[0]} observations"
                        )
                    else:
                        st.info("No observations recorded for this preserve yet.")
                    
                    st.markdown("---") 

                    st.markdown("#### 3. All Species Observed at this Preserve")
                    st.dataframe(pd.DataFrame(results[1])) # Result 2
                    
                    st.markdown("#### 4. Environmental Data")
                    st.dataframe(pd.DataFrame(results[2])) # Result 3
                    
                else:
                    st.warning("Could not fetch all dashboard components. (Expected 4 results)")
                cursor.close()
        else:
            st.warning("No preserves found in the database.")
    except Exception as e:
        st.error(f"An error occurred while loading dashboard: {e}")


# -----------------------------------------------------
# TAB 2: ADD DATA (Observations, Plans, Assignments)
# -----------------------------------------------------
with tab_add_data:
    st.header("Add Data to the Database")
    
    # --- Load shared data for forms ---
    try:
        species_list_df_for_forms = run_query("SELECT SP_ID, SP_NAME FROM species")
        species_options_for_forms = species_list_df_for_forms['SP_ID'] + " - " + species_list_df_for_forms['SP_NAME']
    except Exception:
        species_options_for_forms = []
        
    try:
        preserve_list_df_for_forms = run_query("SELECT P_ID, PNAME FROM species_preserves")
        preserve_options_for_forms = preserve_list_df_for_forms['P_ID'] + " - " + preserve_list_df_for_forms['PNAME']
    except Exception:
        preserve_options_for_forms = []


    # --- Section 1: Add New Observation ---
    with st.container(border=True):
        st.subheader("Add a New Observation")
        st.markdown("Uses `sp_AddNewObservation`. Now links directly to preserves.")
        
        obs_type_options = [
            "Camera Trap", "Drone Sighting", "Footprint Tracking", 
            "Dive Sighting", "Acoustic Monitoring", "Physical Sighting",
            "Scat/Dropping Analysis", "Other"
        ]

        species_mode = st.radio("Species:", ("Select from existing", "Add a new species"), horizontal=True, key="species_mode")

        # --- NEW: HYBRID LOCATION FORM ---
        st.subheader("Observation Location")
        location_mode = st.radio(
            "Where did this observation happen?",
            ("At a registered preserve", "At a new/custom location"),
            horizontal=True, key="loc_mode"
        )
        
        if 'location_results' not in st.session_state:
            st.session_state['location_results'] = []

        if location_mode == "At a new/custom location":
            with st.form("search_location_form"):
                location_query = st.text_input("Search for a location (e.g., 'Eiffel Tower')")
                submitted_search = st.form_submit_button("Find Locations")
            
            if submitted_search:
                if not location_query:
                    st.warning("Please enter a location to search.")
                else:
                    try:
                        geolocator = Nominatim(user_agent="wildlife_app", timeout=5)
                        locations = geolocator.geocode(location_query, exactly_one=False, limit=10, language="en")
                        if locations:
                            all_addresses = [loc.address for loc in locations]
                            unique_addresses = list(dict.fromkeys(all_addresses)) 
                            st.session_state['location_results'] = unique_addresses
                            st.success(f"Found {len(unique_addresses)} unique matches. Select one below.")
                        else:
                            st.session_state['location_results'] = []; st.error("No locations found.")
                    except (GeocoderTimedOut, GeocoderUnavailable):
                        st.error("Geolocation service timed out.")
        # --- END HYBRID LOCATION FORM ---

        with st.form(key="add_observation_form"):
            if species_mode == "Select from existing":
                selected_species_option = st.selectbox("Which species?", species_options_for_forms)
            else: 
                st.warning("You are adding a new species. This will be permanent.")
                c1, c2, c3 = st.columns(3)
                new_sp_id = c1.text_input("New Species ID (e.g., S006)")
                new_sp_name = c2.text_input("New Species Name (e.g., Siberian Tiger)")
                new_sp_class = c3.text_input("Classification (e.g., Mammal)")
            
            st.subheader("Observation Details")
            c1, c2 = st.columns(2)
            obs_id = c1.text_input("Observation ID (e.g., O06)")
            obs_date = c1.date_input("Observation Date", date.today())
            obs_type = c2.selectbox("Observation Type", obs_type_options)
            
            # --- NEW: Final Location/Preserve Selection ---
            final_obs_loc = None # Will store the text
            final_p_id = None    # Will store the ID (or None)

            if location_mode == "At a registered preserve":
                selected_preserve_option = c2.selectbox("Select Preserve:", preserve_options_for_forms)
            else: # "At a new/custom location"
                if not st.session_state['location_results']:
                    st.warning("Please search for a location above.")
                    selected_custom_loc = c2.selectbox("Location:", [], disabled=True)
                else:
                    selected_custom_loc = c2.selectbox("Select the correct Location:", st.session_state['location_results'])
            # --- END NEW ---

            submitted_obs = st.form_submit_button("Add Observation")

        if submitted_obs:
            selected_sp_id = None 
            cursor = None 
            
            try:
                # --- NEW: Finalize location variables before calling procedure ---
                if location_mode == "At a registered preserve":
                    final_p_id = selected_preserve_option.split(" - ")[0]
                    final_obs_loc = selected_preserve_option.split(" - ")[1] # Use the preserve's name
                else:
                    final_p_id = None # Ad-hoc location, so P_ID is NULL
                    final_obs_loc = selected_custom_loc # The full geocoded address
                # --- END NEW ---
                
                cursor = conn.cursor() 
                
                if species_mode == "Add a new species":
                    if not new_sp_id or not new_sp_name or not new_sp_class:
                        st.error("Please fill out all New Species fields."); st.stop() 
                    cursor.execute("INSERT INTO species (SP_ID, SP_NAME, CLASSIFICATION) VALUES (%s, %s, %s)", (new_sp_id, new_sp_name, new_sp_class))
                    selected_sp_id = new_sp_id 
                else: 
                    selected_sp_id = selected_species_option.split(" - ")[0]

                if not obs_id or not selected_sp_id or not obs_type or not final_obs_loc:
                    st.warning("Please fill out all observation fields."); st.stop()
                
                # Call the new procedure with 6 arguments
                cursor.callproc('sp_AddNewObservation', [
                    obs_id, selected_sp_id, obs_date, 
                    obs_type, final_obs_loc, final_p_id 
                ])
                for result in cursor.stored_results(): pass 
                
                conn.commit() 
                st.success(f"Successfully added observation '{obs_id}'!"); st.balloons()
                st.session_state['location_results'] = []
            except mysql.connector.Error as err:
                conn.rollback()
                if err.errno == 1062: 
                    if species_mode == "Add a new species": st.error(f"DATABASE ERROR: A species with ID '{new_sp_id}' OR an observation with ID '{obs_id}' already exists. No data was saved.")
                    else: st.error(f"DATABASE ERROR: An observation with ID '{obs_id}' already exists. No data was saved.")
                else: st.error(f"Database Error: {err.msg}")
            except Exception as e:
                conn.rollback(); st.error(f"An error occurred: {e}")
            finally:
                if cursor: cursor.close() 

    # --- Section 2: Add Conservation Plan (Tests Trigger) ---
    with st.container(border=True):
        st.subheader("Add a New Conservation Plan")
        st.markdown("Tests `trg_ValidateProjectDates`. Try entering an End Date that is *before* the Start Date.")
        
        with st.form("add_plan_form"):
            c1, c2 = st.columns(2)
            plan_id = c1.text_input("Project ID (e.g., CP05)")
            plan_name = c2.text_input("Project Name")
            plan_start = c1.date_input("Start Date")
            plan_end = c2.date_input("End Date")
            plan_species_option = st.selectbox("Related Species", species_options_for_forms, key="plan_sp")
            
            submitted_plan = st.form_submit_button("Add Plan")
        
        if submitted_plan:
            cursor = None
            try:
                plan_sp_id = plan_species_option.split(" - ")[0]
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO conservation_plan (PROJ_ID, PROJ_NAME, STRDATE, END_DATE, SP_ID) VALUES (%s, %s, %s, %s, %s)",
                    (plan_id, plan_name, plan_start, plan_end, plan_sp_id)
                )
                conn.commit()
                st.success(f"Successfully added project '{plan_name}'!")
            except mysql.connector.Error as err:
                st.error(f"DATABASE ERROR: {err.msg}") # This will show the trigger error
            except Exception as e:
                st.error(f"An error occurred: {e}")
            finally:
                if cursor: cursor.close()

    # --- Section 3: Assign Species to Plan (Uses Procedure) ---
    with st.container(border=True):
        st.subheader("Assign a Species to a Plan")
        st.markdown("Uses the `sp_AssignSpeciesToPlan` stored procedure.")
        
        try:
            plan_list_df = run_query("SELECT PROJ_ID, PROJ_NAME FROM conservation_plan")
            plan_options = plan_list_df['PROJ_ID'] + " - " + plan_list_df['PROJ_NAME']
        except Exception:
            plan_options = []

        with st.form("assign_species_form"):
            assign_species_option = st.selectbox("Species to Assign", species_options_for_forms, key="assign_sp")
            assign_plan_option = st.selectbox("Plan to Assign To", plan_options, key="assign_plan")
            assign_status = st.text_input("Initial Status", "Actively Monitored")
            
            submitted_assign = st.form_submit_button("Assign Species")

        if submitted_assign:
            cursor = None
            try:
                assign_sp_id = assign_species_option.split(" - ")[0]
                assign_proj_id = assign_plan_option.split(" - ")[0]
                cursor = conn.cursor(dictionary=True) 
                cursor.callproc('sp_AssignSpeciesToPlan', [assign_sp_id, assign_proj_id, assign_status])
                
                for result in cursor.stored_results():
                    fetched_data = result.fetchall()
                    if fetched_data:
                        st.success(fetched_data[0]['message'])
                        
                conn.commit()
            except mysql.connector.Error as err:
                st.error(f"DATABASE ERROR: {err.msg}")
            except Exception as e:
                st.error(f"An error occurred: {e}")
            finally:
                if cursor: cursor.close()

    # --- Section 4: Add Environmental Data (Tests Trigger) ---
    with st.container(border=True):
        st.subheader("Add New Environmental Data")
        st.markdown("Tests `trg_AlertOnCriticalEnvData`. Try adding data with `AIRQUAL` > 150.")
        
        with st.form("add_env_form"):
            c1, c2, c3 = st.columns(3)
            env_data_id = c1.text_input("Data ID (e.g., D05)")
            env_preserve_option = c2.selectbox("Related Preserve", preserve_options_for_forms)
            env_water = c1.number_input("Water Condition (pH)", value=7.0, step=0.1)
            env_weather = c2.text_input("Weather", "Clear")
            env_soil = c1.text_input("Soil Comp", "Loamy")
            env_air = c2.number_input("Air Quality (AQI)", value=50) 
            
            submitted_env = st.form_submit_button("Add Environmental Data")
        
        if submitted_env:
            cursor = None
            try:
                env_p_id = env_preserve_option.split(" - ")[0]
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO environmental_data (DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL, P_ID) VALUES (%s, %s, %s, %s, %s, %s)",
                    (env_data_id, str(env_water), env_weather, env_soil, str(env_air), env_p_id)
                )
                conn.commit()
                st.success(f"Successfully added environmental data '{env_data_id}'!")
                
                if env_air > 150:
                    st.warning("Trigger Fired! A critical air quality alert was generated.")
                if env_water < 6.0:
                    st.warning("Trigger Fired! A critical water condition alert was generated.")
                
            except mysql.connector.Error as err:
                st.error(f"DATABASE ERROR: {err.msg}")
            except Exception as e:
                st.error(f"An error occurred: {e}")
            finally:
                if cursor: cursor.close()
                
    # --- Section 5: Add a New Preserve ---
    with st.container(border=True):
        st.subheader("Add a New Preserve")
        st.markdown("This adds a new entry to the `species_preserves` table.")
        
        with st.form("add_preserve_form"):
            c1, c2 = st.columns(2)
            p_id = c1.text_input("Preserve ID (e.g., P05)")
            p_name = c2.text_input("Preserve Name (e.g., 'New Tiger Reserve')")
            p_loc = c1.text_input("Location (e.g., 'Sumatra, Indonesia')")
            p_eco = c2.text_input("Ecosystem (e.g., 'Tropical Rainforest')")
            preserve_species_option = st.selectbox("Primary Species for this Preserve", species_options_for_forms, key="preserve_sp")
            
            submitted_preserve = st.form_submit_button("Add Preserve")
        
        if submitted_preserve:
            cursor = None
            try:
                preserve_sp_id = preserve_species_option.split(" - ")[0]
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO species_preserves (P_ID, PLOC, PNAME, PECOSYSTEM, SP_ID) VALUES (%s, %s, %s, %s, %s)",
                    (p_id, p_loc, p_name, p_eco, preserve_sp_id)
                )
                conn.commit()
                st.success(f"Successfully added new preserve '{p_name}'!")
            except mysql.connector.Error as err:
                if err.errno == 1062:
                    st.error(f"Error: A preserve with ID '{p_id}' already exists.")
                else:
                    st.error(f"DATABASE ERROR: {err.msg}")
            except Exception as e:
                st.error(f"An error occurred: {e}")
            finally:
                if cursor: cursor.close()


# -----------------------------------------------------
# TAB 3: REPORTS & STATISTICS (Uses Functions)
# -----------------------------------------------------
with tab_reports:
    st.header("Reports & Statistics")
    st.write("This page calls your SQL functions to generate reports.")

    # --- Report 1: Project Durations ---
    st.subheader("Project Durations (uses `fn_GetProjectDurationDays`)")
    try:
        projects_df = run_query("SELECT PROJ_ID, PROJ_NAME FROM conservation_plan")
        if not projects_df.empty:
            durations = []
            cursor = conn.cursor()
            for proj_id in projects_df['PROJ_ID']:
                cursor.execute(f"SELECT fn_GetProjectDurationDays('{proj_id}')")
                duration = cursor.fetchone()[0]
                durations.append(duration)
            cursor.close()
            
            projects_df['Duration in Days'] = durations
            st.dataframe(projects_df)
        else:
            st.info("No conservation plans to report on.")
    except Exception as e:
        st.error(f"An error occurred: {e}")

    # --- Report 2: Preserve Counts ---
    st.subheader("Species Count per Preserve (uses `fn_GetSpeciesCountInPreserve`)")
    try:
        preserves_df = run_query("SELECT P_ID, PNAME FROM species_preserves")
        if not preserves_df.empty:
            counts = [] 
            cursor = conn.cursor()
            for p_id in preserves_df['P_ID']:
                cursor.execute(f"SELECT fn_GetSpeciesCountInPreserve('{p_id}')")
                count = cursor.fetchone()[0]
                counts.append(count)
            cursor.close()
            
            preserves_df['Species Count'] = counts
            st.dataframe(preserves_df)
        else:
            st.info("No preserves to report on.")
    except Exception as e:
        st.error(f"An error occurred: {e}")

    # --- Report 3: Last Observation ---
    st.subheader("Last Observation Date per Species (uses `fn_GetLastObservationDate`)")
    try:
        species_df = run_query("SELECT SP_ID, SP_NAME FROM species")
        if not species_df.empty:
            last_dates = []
            cursor = conn.cursor()
            for sp_id in species_df['SP_ID']:
                cursor.execute(f"SELECT fn_GetLastObservationDate('{sp_id}')")
                last_date = cursor.fetchone()[0]
                last_dates.append(last_date)
            cursor.close()
            
            species_df['Last Observation Date'] = last_dates
            st.dataframe(species_df)
        else:
            st.info("No species to report on.")
    except Exception as e:
        st.error(f"An error occurred: {e}")

    # --- Report 4: View Alerts Table ---
    st.subheader("Critical Alerts Log")
    st.write("This table is populated by the `trg_AlertOnCriticalEnvData` trigger.")
    try:
        alerts_df = run_query("SELECT * FROM Alerts ORDER BY Timestamp DESC")
        if not alerts_df.empty:
            st.dataframe(alerts_df)
        else:
            st.info("No alerts have been triggered yet.")
    except Exception as e:
        st.error(f"An error occurred: {e}")


# -----------------------------------------------------
# TAB 4: RAW DATA TABLES
# -----------------------------------------------------
with tab_raw_data:
    st.header("Raw Data Tables")
    
    with st.expander("Show/Hide Species List"):
        st.dataframe(run_query("SELECT * FROM species"))
        
    with st.expander("Show/Hide All Observations"):
        st.dataframe(run_query("SELECT * FROM observations"))

    with st.expander("Show/Hide Preserves"):
        st.dataframe(run_query("SELECT * FROM species_preserves"))

    with st.expander("Show/Hide Conservation Plans"):
        st.dataframe(run_query("SELECT * FROM conservation_plan"))

    with st.expander("Show/Hide 'Protected By' Links"):
        st.dataframe(run_query("SELECT * FROM protected_by"))
        
    with st.expander("Show/Hide Environmental Data"):
        st.dataframe(run_query("SELECT * FROM environmental_data"))