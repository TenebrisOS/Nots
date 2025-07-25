from flask import Flask, request, jsonify, make_response
import json
import sys
import deco as d
import threading
import secrets
import os
import time
import re
def help():
    print("\033[1;36mAvailable Commands:\033[0m")
    print("  generate       Generate a 32-character token that can be used to authenticate from the mobile app")
    print("  tokens         Outputs every generated token related to its user")
    print("  remove         Removes a chosen token")
    print("  clear          Clear the screen")
    print("  exit           Exit the program")
    print("  help           Show this help message")

def token_to_json(file_path, token, username):
    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            json.dump({}, f)
            print("A new file has been created, make sure tokens.json permissions is correctly configured on your system. Otherwise, this will lead into a security issue.")

    with open(file_path, 'r') as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            data = {}

    data[token] = username

    with open(file_path, 'w') as f:
        json.dump(data, f, indent=4)

    print(f"Token added: {token} -> {username}")

def validate_username(username):
    # Rule 1: Only letters, digits, underscore
    if not re.match(r'^[A-Za-z][A-Za-z0-9_]*$', username):
        return False, "Username must start with a letter and contain only letters, digits, or underscores."

    # Rule 2: Length
    if len(username) < 4 or len(username) > 16:
        return False, "Username must be between 4 and 16 characters."

    # Rule 3: No consecutive underscores
    if "__" in username:
        return False, "Username cannot contain consecutive underscores."

    # Rule 4: Reserved words
    reserved = {"admin", "root", "system", "null"}
    if username.lower() in reserved:
        return False, "This username is reserved."

    return True, "all good"

def read_console():
    time.sleep(1)
    while True:
        cmd = input("$: ")
        if cmd == "exit" :
            print("Exiting...")
            sys.exit()
        elif cmd == "generate":
            username=input("Enter a new username: ")
            if (os.path.exists(datapath+username)):
                print("Username already exists, please choose another one.")
            else:
                var, why = validate_username(username)
                if var== True:
                    print('Generating token for '+username+', make sure to preserve it somewhere safe. You still can recheck your tokens using the "token" command!')
                    token=gen_token()
                    print(d.green+ token + d.nc)
                    print('Use command "clear" to hide the token!')
                    token_to_json("tokens.json", token, username)
                    os.makedirs(datapath+username, exist_ok=False)
                else:
                   print(why)
        elif cmd == "clear":
            os.system('cls' if os.name == 'nt' else 'clear')
        elif cmd == "help":
            help()
        elif cmd == "tokens":
            readtokens()
        elif cmd == "remove":
            removeatoken()
        else:
            print('Unknown command, type "help" to output every known command.')

def removeatoken():
    return

def readtokens():
    with open("tokens.json", "r") as f:
        jsondata=json.load(f)
    for token in jsondata:
        print(token + "     " +jsondata[token])

def gen_token():
    token = secrets.token_hex(16)
    return token

app = Flask(__name__)
datapath = 'data/'

@app.route('/status', methods=['GET'])
def status():
    response=make_response("Server running!")
    response.status_code=200
    return response

@app.route('/notes', methods=['POST'])
def send_notes():
    request_data=request.json
    token=request_data.get("token")
    with open("tokens.json", 'r') as f:
        data=json.load(f)
        if token in data:
            response=make_response("Access Granted!")
            response.status_code=200
            return response
        else:
            response=make_response("Access Denied!")
            response.status_code=401
            return response

@app.route("/")
def hi():
    return "<p>Hi</p>"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        threading.Thread(target=read_console, daemon=True).start()
        print(d.info+"Launching server script on port: "+d.green+ sys.argv[1])
        app.run('0.0.0.0',sys.argv[1])
    else:
        print("You must specify a port number!")
