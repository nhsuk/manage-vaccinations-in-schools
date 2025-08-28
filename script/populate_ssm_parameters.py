#!/usr/bin/env python3

import argparse
import sys
import os
import boto3
import yaml
from typing import Dict, List, Any


def load_yaml_config(file_path: str) -> Dict[str, Any]:
    """Load and parse YAML configuration file."""
    try:
        with open(file_path, 'r') as f:
            return yaml.safe_load(f)['tunable_vars']
    except FileNotFoundError:
        print(f"Error: Container variables file '{file_path}' not found")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error: Failed to parse YAML file '{file_path}': {e}")
        sys.exit(1)


def extract_cloud_variables(config: Dict[str, Any], environment: str, server_type: str) -> List[str]:
    """Extract cloud variables from YAML config for the given environment and server type."""
    cloud_vars = []
    
    env_config = config[environment]
    if server_type in env_config:
        for key, value in env_config[server_type].items():
            cloud_vars.append(f"{key}={value}")
    
    return cloud_vars


def update_ssm_parameter(parameter_name: str, values: List[str], app_version: str) -> None:
    """Update SSM parameter with StringList values."""
    try:
        ssm = boto3.client('ssm')
        values.append(f"app_version={app_version}")
        string_list = ','.join(values)
        
        print(f"Updating SSM parameter: {parameter_name}")
        
        ssm.put_parameter(
            Name=parameter_name,
            Value=string_list,
            Type='StringList',
            Overwrite=True
        )
        
    except Exception as e:
        print(f"Error: Failed to update SSM parameter '{parameter_name}': {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Populate SSM parameter store from cloud_variables configuration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s sandbox-alpha web
  %(prog)s production good-job
        """
    )

    parser.add_argument('environment', help='Environment name (e.g., qa, production, etc.)')
    parser.add_argument('server_type', help='Server type')
    parser.add_argument('-c', '--config-file', default='config/container_variables.yml', 
                       help='Container variables file path (default: config/container_variables.yml)')
    parser.add_argument('--app-version', default='unknown', help='Application version (default: unknown)')

    args = parser.parse_args()

    # Validate config file exists
    if not os.path.isfile(args.config_file):
        print(f"Error: Container config file '{args.config_file}' not found")
        sys.exit(1)

    config = load_yaml_config(args.config_file)
    cloud_vars = extract_cloud_variables(config, args.environment, args.server_type)

    ssm_parameter_path = f"/{args.environment}/envs/{args.server_type}"
    update_ssm_parameter(ssm_parameter_path, cloud_vars, args.app_version)

    print(f"Cloud variables updated successfully")

if __name__ == '__main__':
    main()