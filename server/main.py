import os
import json
import uuid
from datetime import datetime, timezone
from functools import wraps
import sys
import threading
import secrets
import time
import re

from flask import Flask, request, jsonify, make_response
from flask_cors import CORS

try:
    import deco as d
except ImportError:
    class DecoyDeco:
        def __getattr__(self, name):
            return ""
    d = DecoyDeco()


app = Flask(__name__)
CORS(app)

DATA_PATH = 'data/'

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TOKENS_FILE = os.path.join(BASE_DIR, 'tokens.json')

def ensure_data_path():
    """Ensures the DATA_PATH directory exists (for user note files)."""
    if not os.path.exists(DATA_PATH):
        os.makedirs(DATA_PATH)
        print(f"Created data directory for user notes at: {DATA_PATH}")

def load_json_file(file_path, default_data=None):
    """Loads a JSON file. Returns default_data if file doesn't exist or is invalid."""
    if DATA_PATH in file_path:
        ensure_data_path()

    if default_data is None:
        default_data = {}
    if not os.path.exists(file_path):
        if file_path == TOKENS_FILE:
            try:
                with open(file_path, 'w') as f:
                    json.dump(default_data, f, indent=4)
                print(f"Created tokens file at: {file_path}")
            except IOError as e:
                app.logger.error(f"Error creating file {file_path}: {e}")
                return default_data # Or raise error
        return default_data
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        app.logger.warning(f"Warning: Could not decode JSON from {file_path}. Returning default.")
        return default_data

def save_json_file(file_path, data):
    """Saves data to a JSON file."""
    if DATA_PATH in file_path:
        ensure_data_path()
    try:
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=4)
    except IOError as e:
        app.logger.error(f"Error saving JSON to {file_path}: {e}")

def get_user_notes_file(username):
    """Returns the path to the user's notes JSON file (inside DATA_PATH)."""
    return os.path.join(DATA_PATH, f"{username}.json")

def help_console():
    print(f"{d.green}--- Server Console Commands ---{d.nc}")
    print(f"  {d.cyan}generate{d.nc}       Generate a new token for a user.")
    print(f"  {d.cyan}tokens{d.nc}         List all token-to-username mappings.")
    print(f"  {d.cyan}remove{d.nc}         Remove a specific token.")
    print(f"  {d.cyan}clear{d.nc}          Clear the console screen.")
    print(f"  {d.cyan}exit{d.nc}           Shutdown the server and console.")
    print(f"  {d.cyan}help{d.nc}           Show this help message.")

def validate_username_console(username):
    if not re.match(r'^[A-Za-z][A-Za-z0-9_]*$', username):
        return False, "Username must start with a letter and contain only letters, digits, or underscores."
    if len(username) < 3 or len(username) > 20: # Adjusted length
        return False, "Username must be between 3 and 20 characters."
    if "__" in username:
        return False, "Username cannot contain consecutive underscores."
    reserved = {"admin", "root", "system", "null", "api", "status"}
    if username.lower() in reserved:
        return False, f"Username '{username}' is reserved."
    return True, "Username is valid."

def generate_token_console():
    username = input("Enter username for the new token: ").strip()
    is_valid, message = validate_username_console(username)
    if not is_valid:
        print(f"{d.red}Error: {message}{d.nc}")
        return

    tokens = load_json_file(TOKENS_FILE, {})
    # Check if username already has a token
    for token_val, user_val in tokens.items():
        if user_val == username:
            print(f"{d.yellow}Warning: User '{username}' already has a token: {token_val}{d.nc}")
            if input("Overwrite existing token? (y/N): ").lower() != 'y':
                return

            del tokens[token_val]
            break

    new_token = secrets.token_hex(24) # Longer token
    tokens[new_token] = username # Store as token: username
    save_json_file(TOKENS_FILE, tokens)

    user_notes_file = get_user_notes_file(username)
    if not os.path.exists(user_notes_file):
        save_json_file(user_notes_file, [])

    print(f"{d.green}Token generated for user '{username}':{d.nc}")
    print(f"{d.cyan}{new_token}{d.nc}")
    print("Store this token securely. It's needed for app authentication.")

def list_tokens_console():
    tokens = load_json_file(TOKENS_FILE, {})
    if not tokens:
        print("No tokens found.")
        return
    print(f"{d.green}--- Active Tokens ---{d.nc}")
    for token, username in tokens.items():
        print(f"  User: {d.yellow}{username}{d.nc}, Token: {d.cyan}{token}{d.nc}")

def remove_token_console():
    token_to_remove = input("Enter token to remove: ").strip()
    tokens = load_json_file(TOKENS_FILE, {})
    if token_to_remove in tokens:
        username = tokens.pop(token_to_remove) # Remove and get username
        save_json_file(TOKENS_FILE, tokens)
        print(f"{d.green}Token for user '{username}' removed successfully.{d.nc}")
    else:
        print(f"{d.red}Error: Token not found.{d.nc}")

def read_console_input():
    time.sleep(0.5)
    help_console()
    while True:
        try:
            cmd = input(f"{d.blue}$ {d.nc}").strip().lower()
            if cmd == "exit":
                print("Exiting console and shutting down server...")
                os._exit(0)
            elif cmd == "generate":
                generate_token_console()
            elif cmd == "clear":
                os.system('cls' if os.name == 'nt' else 'clear')
            elif cmd == "help":
                help_console()
            elif cmd == "tokens":
                list_tokens_console()
            elif cmd == "remove":
                remove_token_console()
            elif not cmd:
                continue
            else:
                print(f"{d.red}Unknown command. Type 'help' for available commands.{d.nc}")
        except KeyboardInterrupt:
            print("\nExiting console and shutting down server...")
            os._exit(0)
        except Exception as e:
            print(f"{d.red}Console Error: {e}{d.nc}")


def token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization')

        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(" ")[1]

        if not token:
            return jsonify({"error": "Authorization token is missing"}), 401

        tokens_map = load_json_file(TOKENS_FILE, {})
        current_username = tokens_map.get(token)

        if not current_username:
            return jsonify({"error": "Invalid or expired token"}), 401

        return f(current_username, *args, **kwargs)
    return decorated_function


@app.route("/")
def hello():
    return "<p>Notes App Server is running!</p>"

@app.route('/api/v1/status', methods=['GET'])
def server_status():
    """Provides server status. Can also be used to check token validity if token is provided."""
    token = None
    auth_header = request.headers.get('Authorization')
    is_token_valid = False

    if auth_header and auth_header.startswith('Bearer '):
        token = auth_header.split(" ")[1]
        tokens_map = load_json_file(TOKENS_FILE, {})
        if token in tokens_map:
            is_token_valid = True

    if is_token_valid:
        return jsonify({"message": "Server running and token is valid", "status": "ok_authenticated"}), 200
    else:
        return jsonify({"message": "Server running. Token invalid or not provided.", "status": "ok_unauthenticated"}), 200


@app.route('/api/v1/notes/create', methods=['POST'])
@token_required
def create_note_route(current_username): # current_username is passed by @token_required
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body is missing JSON data"}), 400

        title = data.get('title', '').strip()
        content = data.get('content')

        if content is None: # Content is mandatory
            return jsonify({"error": "Note content is required"}), 400
        if not title:
            title = "Untitled Note"

        note_id = str(uuid.uuid4())
        # Use timezone-aware UTC timestamps
        timestamp = datetime.now(timezone.utc).isoformat()

        new_note_data = {
            "id": note_id,
            "title": title,
            "content": content,
            "created_at": timestamp,
            "updated_at": timestamp
        }

        user_notes_file = get_user_notes_file(current_username)
        notes_list = load_json_file(user_notes_file, []) # Default to empty list
        notes_list.append(new_note_data)
        save_json_file(user_notes_file, notes_list)

        # Client expects id, title, updated_at for NoteMetadata
        response_for_client = {
            "id": new_note_data["id"],
            "title": new_note_data["title"],
            "updated_at": new_note_data["updated_at"]
        }
        return jsonify(response_for_client), 201 # 201 Created

    except Exception as e:
        app.logger.error(f"Error in /notes/create for user {current_username}: {e}")
        return jsonify({"error": "An internal server error occurred while creating the note"}), 500


@app.route('/api/v1/notes/', methods=['GET'])
@token_required
def get_notes_route(current_username):
    try:
        user_notes_file = get_user_notes_file(current_username)
        notes_list = load_json_file(user_notes_file, [])

        metadata_list = [
            {"id": note["id"], "title": note["title"], "updated_at": note["updated_at"]}
            for note in notes_list
        ]

        return jsonify(metadata_list), 200

    except Exception as e:
        app.logger.error(f"Error in /notes (GET) for user {current_username}: {e}")
        return jsonify({"error": "An internal server error occurred while fetching notes"}), 500

@app.route('/api/v1/notes/<string:note_id>/', methods=['GET'])
@token_required
def get_single_note_route(current_username, note_id):
    try:
        user_notes_file = get_user_notes_file(current_username)
        notes_list = load_json_file(user_notes_file, [])

        note_to_return = next((note for note in notes_list if note.get("id") == note_id), None)

        if note_to_return:
            return jsonify(note_to_return), 200
        else:
            return jsonify({"error": "Note not found"}), 404

    except Exception as e:
        app.logger.error(f"Error in /notes/<note_id> for user {current_username}: {e}")
        return jsonify({"error": "An internal server error"}), 500

@app.route('/api/v1/notes/<string:note_id>/', methods=['DELETE'])
@token_required
def delete_note_route(current_username, note_id):
    try:
        user_notes_file = get_user_notes_file(current_username)
        notes_list = load_json_file(user_notes_file, [])

        original_length = len(notes_list)
        notes_list = [note for note in notes_list if note.get("id") != note_id]

        if len(notes_list) < original_length:
            save_json_file(user_notes_file, notes_list)
            return jsonify({"message": "Note deleted successfully"}), 200 # or 204 No Content
        else:
            return jsonify({"error": "Note not found or already deleted"}), 404

    except Exception as e:
        app.logger.error(f"Error in /notes/<note_id> (DELETE) for user {current_username}: {e}")
        return jsonify({"error": "An internal server error"}), 500


@app.route('/api/v1/notes/<string:note_id>/', methods=['PUT'])
@token_required
def update_note_route(current_username, note_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body is missing JSON data"}), 400

        title = data.get('title', '').strip()
        content = data.get('content')

        if content is None and not title:
            return jsonify({"error": "No data provided for update (title or content required)"}), 400

        user_notes_file = get_user_notes_file(current_username)
        notes_list = load_json_file(user_notes_file, [])
        note_found = False
        updated_note_response = {}

        for i, note in enumerate(notes_list):
            if note.get("id") == note_id:
                if title: # Update title if provided
                    notes_list[i]["title"] = title
                if content is not None: # Update content if provided
                    notes_list[i]["content"] = content

                notes_list[i]["updated_at"] = datetime.now(timezone.utc).isoformat()
                note_found = True

                updated_note_response = {
                    "id": notes_list[i]["id"],
                    "title": notes_list[i]["title"],
                    # "content": notes_list[i]["content"], # Optionally return full content
                    "updated_at": notes_list[i]["updated_at"]
                }
                break

        if note_found:
            save_json_file(user_notes_file, notes_list)
            return jsonify(updated_note_response), 200
        else:
            return jsonify({"error": "Note not found"}), 404

    except Exception as e:
        app.logger.error(f"Error in /notes/<note_id> (PUT) for user {current_username}: {e}")
        return jsonify({"error": "An internal server error occurred while updating the note"}), 500

if __name__ == "__main__":
    ensure_data_path()

    load_json_file(TOKENS_FILE, {})

    port_arg = 5000 # Default port
    if len(sys.argv) > 1:
        try:
            port_arg = int(sys.argv[1])
        except ValueError:
            print(f"{d.red}Warning: Invalid port '{sys.argv[1]}'. Using default port {port_arg}.{d.nc}")
    else:
        print(f"{d.yellow}No port specified. Using default port {port_arg}.{d.nc}")
        print(f"{d.yellow}Usage: python your_script_name.py <port_number>{d.nc}")

    console_thread = threading.Thread(target=read_console_input, daemon=True)
    console_thread.start()

    print(f"{d.green}Launching Flask server on port: {port_arg}{d.nc}")
    print(f"{d.magenta}Console available for server commands. Type 'help'.{d.nc}")

    app.run(host='0.0.0.0', port=port_arg, debug=False)
