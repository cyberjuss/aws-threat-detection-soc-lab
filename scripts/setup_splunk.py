# setup_splunk.py
# Creates the Splunk indexes needed for AWS logs. An index is where Splunk stores data;
# we use one per source (CloudTrail, Config, VPC Flow) so searches and retention are clear.
# Run from soc:  python ./scripts/setup_splunk.py

import argparse
import getpass

import splunklib.client as client

# Indexes the lab uses; must exist before the Add-on sends data.
DEFAULT_INDEXES = [
    "aws_cloudtrail",
    "aws_config",
    "aws_vpcflow",
]


def connect_splunk(host, port, username, password):
    """Connect to Splunk API. verify=False for self-signed cert (local Docker)."""
    return client.connect(
        host=host,
        port=port,
        username=username,
        password=password,
        scheme="https",
        verify=False,
    )


def ensure_indexes(service, index_names):
    """Create each index if it doesn't exist."""
    for name in index_names:
        if name in service.indexes:
            print(f"[indexes] {name} already exists")
        else:
            service.indexes.create(name)
            print(f"[indexes] {name} created")

def main():
    parser = argparse.ArgumentParser(description="Create AWS indexes in Splunk")
    parser.add_argument("--host", default="localhost", help="Splunk host")
    parser.add_argument("--port", default=8089, help="Splunk management port")
    parser.add_argument("--username", default="admin", help="Splunk user")
    parser.add_argument("--password", default="ChangeMe123!", help="Splunk password (default)")
    args = parser.parse_args()

    password = getpass.getpass(prompt="Enter your Splunk password: ")
    service = connect_splunk(host=args.host, port=args.port, username=args.username, password=password)
    ensure_indexes(service, DEFAULT_INDEXES)
    print("[setup] Splunk setup complete")


if __name__ == "__main__":
    main()
