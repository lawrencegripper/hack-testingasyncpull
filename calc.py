import json
import sys
from datetime import datetime

input_file = open (sys.argv[1])
json_array = json.load(input_file)

first_time = ""
last_time = ""
container_started = ""

for item in json_array:
    if first_time == "" and item["time"] != None:
        first_time = item["time"]

    if item["reason"] == "Started" and item["message"] == "Started container myapp-container":
        container_started = item["time"]

    last_time = item["time"]

start = datetime.strptime(first_time, "%Y-%m-%dT%H:%M:%SZ")
finish = datetime.strptime(container_started, "%Y-%m-%dT%H:%M:%SZ")

end2end_time = finish - start

print(f"time: {end2end_time.seconds} file: {sys.argv[1]} runat:{datetime.now()}")