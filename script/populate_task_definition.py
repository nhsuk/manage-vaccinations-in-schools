#!/usr/bin/env python3

import argparse
import json
import sys
import os
import boto3
import yaml
from typing import Dict, List, Any

from botocore import args


def load_yaml_config(file_path: str) -> Dict[str, Any]:
    """Load and parse YAML configuration file."""
    try:
        with open(file_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: Container variables file '{file_path}' not found")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error: Failed to parse YAML file '{file_path}': {e}")
        sys.exit(1)


def fetch_ssm_parameter(parameter_name: str) -> Dict[str, Any]:
    """Fetch SSM parameter and parse as JSON."""
    try:
        ssm = boto3.client('ssm')
        response = ssm.get_parameter(Name=parameter_name)
        return json.loads(response['Parameter']['Value'])
    except Exception as e:
        print(f"Error: Failed to fetch SSM parameter '{parameter_name}': {e}")
        sys.exit(1)


def get_image_uri(image_tag: str) -> str:
    sts = boto3.client('sts')
    account_id = sts.get_caller_identity()['Account']

    session = boto3.Session()
    region = session.region_name

    ecr = boto3.client('ecr')
    response = ecr.describe_images(
        repositoryName='mavis/webapp',
        imageIds=[{'imageTag': image_tag}]
    )
    digest = response['imageDetails'][0]['imageDigest']

    registry = f"{account_id}.dkr.ecr.{region}.amazonaws.com"
    return f"{registry}/mavis/webapp@{digest}"


def extract_config_env_vars(config: Dict[str, Any], environment: str) -> Dict[str, str]:
    """Extract environment variables from YAML config for given environment and server type."""
    env_vars = {}

    if 'environments' in config and environment in config['environments']:
        env_config = config['environments'][environment]
        for key, value in env_config.items():
            env_vars[key] = str(value)

    return env_vars


def merge_environment_variables(terraform_vars: List[Dict[str, str]], config_vars: Dict[str, str]) -> List[Dict[str, str]]:
    """Merge terraform environment variables with config file variables."""
    # Convert terraform vars to dict for easier merging
    terraform_dict = {var['name']: var['value'] for var in terraform_vars}

    # Merge config vars into terraform vars (config takes precedence)
    merged_dict = {**terraform_dict, **config_vars}

    # Convert back to ECS task definition format
    return [{'name': key, 'value': value} for key, value in merged_dict.items()]


def filter_secrets(secrets: List[Dict[str, str]], environment_vars: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Filter secrets to only include those that are not already in environment variables."""
    secrets_dict = {secret['name']: secret['valueFrom'] for secret in secrets}
    env_vars_dict = {var['name']: var['value'] for var in environment_vars}

    return [{'name': name, 'valueFrom': value} for name, value in secrets_dict.items() if name not in env_vars_dict]


def health_check_command(server_type: str) -> str:
    if server_type == "web":
        return "./bin/internal_healthcheck http://localhost:4000/health/database"
    elif server_type == "good-job":
        return "./bin/internal_healthcheck http://localhost:4000/status/connected"
    else:
        return "echo 'alive' || exit 1"


def populate_template(template_path: str, output_path: str, replacements: Dict[str, Any]) -> None:
    """Load template and replace placeholders with actual values."""
    try:
        with open(template_path, 'r') as f:
            template_content = f.read()
    except FileNotFoundError:
        print(f"Error: Template file '{template_path}' not found")
        sys.exit(1)

    # Replace all placeholders
    for placeholder, value in replacements.items():
        if isinstance(value, (list, dict)):
            # For JSON objects/arrays, convert to JSON string
            json_value = json.dumps(value, indent=2)
            template_content = template_content.replace(f"<{placeholder}>", json_value)
        else:
            template_content = template_content.replace(f"<{placeholder}>", str(value))

    try:
        with open(output_path, 'w') as f:
            f.write(template_content)
    except Exception as e:
        print(f"Error: Failed to write output file '{output_path}': {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Populate ECS task definition from template",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s sandbox-alpha web -i latest
  %(prog)s sandbox-alpha good-job -i latest -o web-task-definition.json
        """
    )

    parser.add_argument('environment', help='Environment name (e.g., qa, production, etc.)')
    parser.add_argument('server_type', choices=['web', 'good-job'], help='Server type')
    parser.add_argument('-v', '--app-version', default='Unknown', help='Version number to display')
    parser.add_argument('-n', '--server-type-name', help='Name of server type if different from server_type')
    parser.add_argument('-o', '--output', default='task-definition.json', help='Output file path (default: task-definition.json)')
    parser.add_argument('-t', '--template', default='config/templates/task-definition.json.tpl', help='Template file path (default: config/templates/task-definition.json.tpl)')
    parser.add_argument('-c', '--config-file', default='config/container_variables.yml', help='Container variables file path (default: config/container_variables.yml)')
    parser.add_argument('-i', '--image-tag', required=True, help='Docker image URI (required)')
    parser.add_argument('--cpu', default='1024', help='CPU units (default: 1024)')
    parser.add_argument('--memory', default='2048', help='Memory in MB (default: 2048)')

    args = parser.parse_args()
    if not args.server_type_name:
        args.server_type_name = args.server_type

    # Validate files exist
    if not os.path.isfile(args.template):
        print(f"Error: Template file '{args.template}' not found")
        sys.exit(1)

    if not os.path.isfile(args.config_file):
        print(f"Error: Container config file '{args.config_file}' not found")
        sys.exit(1)

    print(f"Populating task definition for mavis-{args.environment}-{args.server_type_name}")
    print(f"Template: {args.template}")
    print(f"Config file: {args.config_file}")
    print(f"Image: {args.image_tag}")

    # Fetch SSM parameter
    ssm_parameter_name = f"/{args.environment}/mavis/ecs/{args.server_type_name}/container_variables"
    print(f"Fetching SSM parameter: {ssm_parameter_name}")
    ssm_data = fetch_ssm_parameter(ssm_parameter_name)

    # Load container variables config
    print(f"Reading container variables from: {args.config_file}")
    config = load_yaml_config(args.config_file)
    config_env_vars = extract_config_env_vars(config, args.environment)
    config_env_vars['APP_VERSION'] = args.app_version

    # Extract data from SSM
    terraform_env_vars = ssm_data.get('task_envs', [])
    secrets_json = ssm_data.get('task_secrets', [])
    execution_role_arn = ssm_data.get('execution_role_arn', '')
    task_role_arn = ssm_data.get('task_role_arn', '')
    image_uri = get_image_uri(args.image_tag)

    # Merge environment variables
    print("Merging environment variables...")
    merged_env_vars = merge_environment_variables(terraform_env_vars, config_env_vars)
    filtered_secrets = filter_secrets(secrets_json, merged_env_vars)

    print("Generated environment variables:")
    print(json.dumps(merged_env_vars, indent=2))

    # Prepare all replacements
    replacements = {
        'ENV': args.environment,
        'SERVER_TYPE_NAME': args.server_type_name,
        'TASK_ROLE_ARN': task_role_arn,
        'EXECUTION_ROLE_ARN': execution_role_arn,
        'HEALTH_CHECK': health_check_command(args.server_type),
        'CPU': args.cpu,
        'MEMORY': args.memory,
        'ENVIRONMENT_VARIABLES': merged_env_vars,
        'SECRETS': filtered_secrets,
        'IMAGE_URI': image_uri
    }

    # Populate template
    print(f"Replacing placeholders in template...")
    populate_template(args.template, args.output, replacements)

    print(f"Task definition populated successfully: {args.output}")
    print(f"Environment: {args.environment}")
    print(f"Server type: {args.server_type}")
    print(f"Server type name: {args.server_type_name}")
    print(f"Image URI: {image_uri}")
    print(f"CPU: {args.cpu}")
    print(f"Memory: {args.memory}")


if __name__ == '__main__':
    main()
