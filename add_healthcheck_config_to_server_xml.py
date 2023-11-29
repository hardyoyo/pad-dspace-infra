#!/usr/bin/env python3
"""Script to modify a Tomcat server.xml file using Docker and plain text processing.

This script fetches the server.xml file from a Docker container, adds a new
HealthCheckValve element to the last Host in the XML, and saves the modified
file locally.

Make sure you have Docker installed and the necessary permissions to run it.

Usage:
    1. Adjust CONTAINER_TOMCAT_CONFIG_PATH, LOCAL_TOMCAT_CONFIG_PATH, and
       BACKEND_IMAGE_TAG as needed.
    2. Run the script.

"""

import subprocess
import sys
import os

CONTAINER_TOMCAT_CONFIG_PATH = '/usr/local/tomcat/conf'
LOCAL_TOMCAT_CONFIG_PATH = 'config/tomcat'
BACKEND_IMAGE_TAG = os.getenv('BACKEND_IMAGE_TAG', 'dspace/dspace:dspace-7_x')

CONTAINER_SERVER_XML = CONTAINER_TOMCAT_CONFIG_PATH + '/server.xml'
LOCAL_SERVER_XML = LOCAL_TOMCAT_CONFIG_PATH + '/server.xml'

# Indicate that we are fetching the server.xml file
print("Fetching the server.xml file from the Docker container...")

docker_command = [
    'docker',
    'run',
    '--rm',
    BACKEND_IMAGE_TAG,
    'cat',
    CONTAINER_SERVER_XML,
]

# Run the Docker command to fetch the server.xml file
with subprocess.Popen(docker_command, cwd=LOCAL_TOMCAT_CONFIG_PATH, stdout=subprocess.PIPE,
                      stderr=subprocess.PIPE) as process:
    output, error = process.communicate()
    if process.returncode != 0:
        print("Error fetching the server.xml file:")
        print("stdout:", output.decode('utf-8'))
        print("stderr:", error.decode('utf-8'))
        sys.exit(1)

    # Write the fetched content to the local server.xml file
    with open(LOCAL_SERVER_XML, 'wb') as local_file:
        local_file.write(output)

# Indicate that we are processing the server.xml file
print("Processing the server.xml file...")

# Identify the line number where we want to insert the new HealthCheckValve
INSERT_LINE_NUMBER = None
with open(LOCAL_SERVER_XML, 'r', encoding='utf-8') as xml_file:
    lines = xml_file.readlines()
    for i, line in enumerate(reversed(lines)):
        if '</Host>' in line:
            INSERT_LINE_NUMBER = len(lines) - i
            break

# Insert the new HealthCheckValve into the identified line
if INSERT_LINE_NUMBER is not None:
    lines.insert(INSERT_LINE_NUMBER,
    '    <Valve className="org.apache.catalina.valves.HealthCheckValve"/>\n')

# Write the modified content back to the local server.xml file
with open(LOCAL_SERVER_XML, 'w', encoding='utf-8') as xml_file:
    xml_file.writelines(lines)

# Indicate success
print("Modification complete. The modified server.xml file is saved locally.")

sys.exit(0)
