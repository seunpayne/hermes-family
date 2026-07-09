#!/usr/bin/env python3
"""Railway GraphQL API helper. Reads token from /tmp/auth_hdr.txt
and provides a `gql()` function.

Usage:
  python3 -c "
import json
from railway_graphql import gql
result = gql('{ __schema { queryType { name } } }')
print(json.dumps(result, indent=2))
"

Requires /tmp/auth_hdr.txt with full Authorization header.
Create it with:
  printf "Authorization: Bearer " > /tmp/auth_hdr.txt
  cat /tmp/railway_token.txt >> /tmp/auth_hdr.txt
"""

import subprocess, json, os

_AUTH_HDR = None  # cached auth header

def _load_auth():
    global _AUTH_HDR
    if _AUTH_HDR is not None:
        return _AUTH_HDR

    hdr_path = "/tmp/auth_hdr.txt"
    tok_path = "/tmp/railway_token.txt"
    ptok_path = "/tmp/railway_project_token.txt"

    if os.path.exists(hdr_path):
        with open(hdr_path) as f:
            _AUTH_HDR = f.read().strip()
        return _AUTH_HDR

    if os.path.exists(ptok_path):
        with open(ptok_path) as f:
            tok = f.read().strip()
        _AUTH_HDR = "Project-Access-Token: " + tok
        return _AUTH_HDR

    if os.path.exists(tok_path):
        with open(tok_path) as f:
            tok = f.read().strip()
        _AUTH_HDR = "Authorization: Bearer " + tok
        return _AUTH_HDR

    raise FileNotFoundError(
        "No token file found. Expected one of:\n"
        f"  {hdr_path} (pre-built auth header)\n"
        f"  {tok_path} (account token)\n"
        f"  {ptok_path} (project token)\n"
        "Create with: printf 'Authorization: Bearer ' > /tmp/auth_hdr.txt &&"
        " cat /tmp/railway_token.txt >> /tmp/auth_hdr.txt"
    )

def gql(query, timeout=15):
    """Execute a GraphQL query against Railway's API."""
    hdr = _load_auth()
    r = subprocess.run([
        "curl", "-s", "https://backboard.railway.com/graphql/v2",
        "-H", hdr,
        "-H", "Content-Type: application/json",
        "-d", json.dumps({"query": query})
    ], capture_output=True, text=True, timeout=timeout)
    return json.loads(r.stdout)


def list_projects(workspace_id):
    q = f"""query {{
        projects(workspaceId: "{workspace_id}") {{
            edges {{ node {{ id name description }} }}
        }}
    }}"""
    return gql(q)


def get_project(project_id):
    q = f"""query {{
        project(id: "{project_id}") {{
            id name description
            environments {{ edges {{ node {{ id name }} }} }}
            services {{ edges {{ node {{ id name }} }} }}
        }}
    }}"""
    return gql(q)


def upsert_variable(project_id, env_id, name, value, service_id=None):
    svc = f'serviceId: "{service_id}", ' if service_id else ""
    q = f"""mutation {{
        variableUpsert(input: {{
            projectId: "{project_id}",
            environmentId: "{env_id}",
            {svc}
            name: "{name}",
            value: "{value}"
        }})
    }}"""
    return gql(q)
