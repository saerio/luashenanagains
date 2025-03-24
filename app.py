from flask import Flask, request, jsonify, send_from_directory
from datetime import datetime, UTC
app = Flask(__name__)

# Mapping of turtle IDs to categories
TURTLE_CATEGORIES = {
    "0": "printer",
    "13": "miner",
    "11": "tree",
    "14": "miner",
    "17": "miner",
    "16": "monitor13",
    "18": "tree",
    "2": "display",
    "4": "door",
    "37": "door-main",
    "38": "door-main",
    "39": "door-submain",
    "40": "door-submain",
    "41": "door-lab",
    "42": "door-storage",
    "43": "door-lab",
    "44": "door-side-nomon",
    "45": "door-submain",
    "46": "display",
    "47": "door-main",
    "49": "storagemonview",
    "6": "atm",
    "53": "storagemon",
    "1": "storagemonview",
    "2": "atm"
}

# Directory where Lua files are stored
LUA_FILES_DIR = "lua_files"

# This dictionary will store fuel levels for each turtle
TURTLE_FUEL_LEVELS = {
    "13": 100,  # Example fuel level (in some unit)
    "11": 80,
    "14": 95,
    "17": 50,
    "16": 75,
}

# This dictionary will store inventory data for each turtle
TURTLE_INVENTORY = {
    "13": [],
    "11": [],
    "14": [],
    "17": [],
    "16": [],
}

# Lockdown status, default is not locked
lockdown = False

# Dummy user database for authentication
USERS = {
    "sopny": "shazam",
    "C1200Games": "openplease"
}


# Allowed access locations per user
USER_ACCESS = {
    "sopny": ["storage", "main", "submain", "lab"],
    "C1200Games": ["main", "submain"] # Modify as needed
}

# Store authentication logs
AUTH_LOGS = []

exit_logs = []
# Admin password for retrieving logs
ADMIN_PASSWORD = "supersecret"  # Change this!



@app.route('/get_lua', methods=['GET'])
def get_lua_file():
    turtle_id = request.headers.get("turtleID")

    if not turtle_id:
        return {"error": "Missing turtleID in headers"}, 400

    category = TURTLE_CATEGORIES.get(turtle_id)
    
    if not category:
        return {"error": "Invalid turtleID"}, 404

    lua_filename = f"{category}.lua"

    try:
        return send_from_directory(LUA_FILES_DIR, lua_filename, as_attachment=True)
    except FileNotFoundError:
        return {"error": f"Lua file '{lua_filename}' not found"}, 404

@app.route("/submit_inventory", methods=['POST'])
def submit_inventory():
    try:
        # Try to parse JSON regardless of content-type header
        if request.is_json:
            data = request.get_json()
        else:
            # For requests without correct content-type header
            data = request.get_json(force=True)
        
        if not data:
            return jsonify({"error": "Invalid or missing JSON"}), 400
        
        # Get the required fields from the data
        turtle_id = data.get("turtleID")
        inventory = data.get("inventory")
        fuel_level = data.get("fuelLevel")
        
        if not turtle_id or inventory is None or fuel_level is None:
            print(turtle_id, inventory, fuel_level)
            return jsonify({"error": "Missing required data fields"}), 400

        
        # Update the fuel level
        TURTLE_FUEL_LEVELS[turtle_id] = fuel_level

        # Update the inventory
        TURTLE_INVENTORY[turtle_id] = inventory
        
        return jsonify({"message": "Inventory data received successfully"}), 200
    except Exception as e:
        print(f"Error processing data: {str(e)}")
        return jsonify({"error": f"Error processing data: {str(e)}"}), 500

@app.route("/get_fuel_level", methods=['GET'])
def get_fuel_level():
    # Get the turtleID from the request headers
    turtle_id = request.headers.get("turtleID")

    if not turtle_id:
        return {"error": "Missing turtleID in headers"}, 400

    # Check if the turtleID exists in the fuel levels dictionary
    fuel_level = TURTLE_FUEL_LEVELS.get(turtle_id)

    if fuel_level is None:
        return {"error": "TurtleID not found or fuel data is unavailable"}, 404

    # Return the current fuel level for the Turtle
    return jsonify({"turtleID": turtle_id, "fuelLevel": fuel_level}), 200

@app.route("/get_inventory", methods=['GET'])
def get_inventory():
    turtle_id = request.headers.get("turtleID")
    
    if not turtle_id:
        return {"error": "Missing turtleID in headers"}, 400
    
    # Get the inventory data for the turtle
    inventory_data = TURTLE_INVENTORY.get(turtle_id)
    
    if inventory_data is None:
        return {"error": "TurtleID not found or inventory data is unavailable"}, 404
    
    return jsonify({
        "turtleID": turtle_id,
        "inventory": inventory_data
    }), 200

def log_auth_attempt(username, leads_to, status):
    """Logs authentication attempts with timestamp."""
    AUTH_LOGS.append({
        "username": username,
        "leads_to": leads_to,
        "status": status,
        "timestamp": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    })
    
    # Keep only the last 50 logs to prevent memory overflow
    if len(AUTH_LOGS) > 50:
        AUTH_LOGS.pop(0)

@app.route("/auth_logs", methods=['GET'])
def get_auth_logs():
    """Returns the last n authentication logs (default: 10)."""
    admin_pass = request.headers.get("adminPassword")
    
    if admin_pass != ADMIN_PASSWORD:
        return jsonify({"error": "Unauthorized"}), 403

    try:
        n = int(request.args.get("limit", 10))  # Default: 10 logs
        return jsonify(AUTH_LOGS[-n:]), 200
    except Exception as e:
        return jsonify({"error": f"Error retrieving logs: {str(e)}"}), 500



@app.route("/vcc/<path:path>")
def path(path):
    return send_from_directory("vcc", path)

@app.route("/setup/turtle")
def startupserve():
    return send_from_directory(LUA_FILES_DIR, "install.lua")

@app.route("/setup/computer")
def startupserve_pc():
    return send_from_directory(LUA_FILES_DIR, "install-pc.lua")

@app.route("/management.lua")
def managementlua():
    return send_from_directory(LUA_FILES_DIR, "management.lua")

@app.route("/management-pc.lua")
def managementluapc():
    return send_from_directory(LUA_FILES_DIR, "management-pc.lua")

@app.route("/lockdown", methods=['GET'])
def get_lockdown_status():
    """Returns the current lockdown status."""
    return jsonify({"lockdown": lockdown}), 200

@app.route("/authenticate", methods=['POST'])
def authenticate_user():
    """Authenticates a user based on username, password, and leads_to access.
    
    IMPORTANT: This function remains **unchanged** in terms of request/response format.
    """
    if lockdown:
        log_auth_attempt("UNKNOWN", "N/A", "LOCKDOWN")
        return "false", 200  # Deny all requests in lockdown mode

    try:
        # Handle form data exactly as before
        data = request.form
        username = data.get("username")
        password = data.get("password")
        leads_to = data.get("leads_to")

        if not username or not password or not leads_to:
            log_auth_attempt(username, leads_to, "MISSING_FIELDS")
            return "false", 401  # Missing fields

        if USERS.get(username) == password:
            if leads_to in USER_ACCESS.get(username, []):
                log_auth_attempt(username, leads_to, "SUCCESS")
                return "true", 200  # Auth success
            else:
                log_auth_attempt(username, leads_to, "FORBIDDEN")
                return "false", 200  # Not authorized for location

        log_auth_attempt(username, leads_to, "FAILED")
        return "false", 200  # Auth failed

    except Exception as e:
        print(f"Error during authentication: {str(e)}")
        return "false", 500  # Internal error

@app.route('/log-exit', methods=['POST'])
def log_exit():
    event_data = {
        "event": "redstone_exit",
        "timestamp": datetime.now(UTC).isoformat()  # Fixed timestamp format
    }
    
    exit_logs.append(event_data)
    
    print(f"Exit event logged: {event_data}")
    
    return jsonify({"success": True, "message": "Exit event logged"}), 200

# Endpoint to retrieve logs (for debugging)
@app.route('/get-logs', methods=['GET'])
def get_logs():
    return jsonify(exit_logs)


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")
