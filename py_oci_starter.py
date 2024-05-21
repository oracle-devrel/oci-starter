#!/usr/bin/env python3
# OCI Starter
#
# Script to create an OCI deployment scaffold with application source code
#
# Authors: Marc Gueury & Ewan Slater
# Date: 2022-11-24
import sys
import os
import shutil
import json
import stat
from datetime import datetime
from distutils.dir_util import copy_tree
from jinja2 import Environment, FileSystemLoader

## constants ################################################################

ABORT = 'ABORT'
GIT = 'git'
CLI = 'cli'
GROUP='group'
ZIP = 'zip'
EXISTING = 'existing'
NEW = 'new'
TO_FILL = "__TO_FILL__"
BASIS_DIR = "basis"

## globals ##################################################################

output_dir = "output"
zip_dir = ""
a_group_common = []

## functions ################################################################

def title(t):
    s = "-- " + t + " "
    return s.ljust(78, '-')


def script_name():
    return os.path.basename(__file__)


def get_mode():
    return params['mode']


def prog_arg_list():
    arr = sys.argv.copy()
    arr.pop(0)
    return arr


def prog_arg_dict():
    return list_to_dict(prog_arg_list())


MANDATORY_OPTIONS = {
    CLI: ['-language', '-deploy_type'],
    GROUP: ['-group_name','-group_common']
}

def mandatory_options(mode):
    return MANDATORY_OPTIONS[mode]


default_options = {
    '-prefix': 'starter',
    '-java_framework': 'springboot',
    '-java_vm': 'graalvm',
    '-java_version': '21',
    '-ui_type': 'html',
    '-db_type': 'atp',
    '-license_model': 'included',
    '-mode': CLI,
    '-infra_as_code': 'terraform_local',
    '-output_dir' : 'output',
    '-db_password' : TO_FILL,
    '-oke_type' : 'managed'
}

no_default_options = ['-compartment_ocid', '-oke_ocid', '-vcn_ocid',
                      '-atp_ocid', '-db_ocid', '-db_compartment_ocid', '-pdb_ocid', '-mysql_ocid', '-psql_ocid', '-opensearch_ocid', '-nosql_ocid',
                      '-db_user', '-fnapp_ocid', '-apigw_ocid', '-bastion_ocid', '-auth_token', '-tls',
                      '-subnet_ocid','-public_subnet_ocid','-private_subnet_ocid','-shape','-db_install', 
                      '-ui', '-deploy', '-database', '-license']

# hidden_options - allowed but not advertised
hidden_options = ['-zip', '-group_common','-group_name']

rename_params = {
  'database': 'db_type',
  'deploy'  : 'deploy_type',
  'ui'      : 'ui_type',
  'license' : 'license_model'
}

def allowed_options():
    return list(default_options.keys()) + hidden_options \
        + mandatory_options(mode) + no_default_options


allowed_values = {
    '-language': {'java', 'node', 'python', 'dotnet', 'go', 'php', 'ords', 'apex', 'none'},
    '-deploy_type': {'compute', 'instance_pool', 'kubernetes', 'function', 'container_instance', 'hpc', 'datascience'},
    '-java_framework': {'springboot', 'helidon', 'helidon4', 'tomcat', 'micronaut'},
    '-java_vm': {'jdk', 'graalvm', 'graalvm-native'},
    '-java_version': {'8', '11', '17', '21'},
    '-kubernetes': {'oke', 'docker'},
    '-ui_type': {'html', 'jet', 'angular', 'reactjs', 'jsp', 'php', 'api', 'apex', 'none'},
    '-db_type': {'atp', 'database', 'dbsystem', 'rac', 'db_free', 'pluggable', 'pdb', 'mysql', 'psql', 'opensearch', 'nosql', 'none'},
    '-license_model': {'included', 'LICENSE_INCLUDED', 'byol', 'BRING_YOUR_OWN_LICENSE'},
    '-infra_as_code': {'terraform_local', 'terraform_object_storage', 'resource_manager'},
    '-mode': {CLI, GIT, ZIP},
    '-shape': {'amd','freetier_amd','ampere','arm'},
    '-db_install': {'default', 'shared_compute', 'kubernetes'},
    '-tls': {'none', 'new_http_01', 'new_dns_01', 'existing_ocid', 'existing_dir'},
    '-oke_type': {'managed', 'virtual_node'}
}

def check_values():
    illegals = {}
    for arg in allowed_values:
        arg_val = prog_arg_dict().get(arg)
        if arg_val is not None:
            if arg_val not in allowed_values[arg]:
                illegals[arg] = arg_val
    return illegals


def get_tf_var(param):
    return 'TF_VAR_' + param


def longhand(key, abbreviations):
    current = params[key]
    if current in abbreviations:
        return abbreviations[current]
    else:
        return current


def pop_param(dict,param):
    if param in dict:
        dict.pop(param)


def save_params():
    p = params.copy()
    pop_param(p,"output_dir")
    pop_param(p,"zip")
    params['params'] = ",".join(p.keys())


def db_rules():
    if params.get('db_type') == 'rac':
        params['db_node_count'] = "2" 

    params['db_type'] = longhand(
        'db_type', {'atp': 'autonomous', 'dbsystem': 'database', 'rac': 'database', 'pdb': 'pluggable'})

    if params.get('db_type') not in ['autonomous', 'db_free']:
        if params.get('language') == 'ords':
            error(f'ORDS not supported')
        if params.get('language') == 'apex':
            error(f'APEX not supported')
    if params.get('db_type') == 'pluggable':
        if (params.get('db_ocid') is None and params.get('pdb_ocid') is None):
            error(f'Pluggable Database needs an existing DB_OCID or PDB_OCID')
    if params.get('db_user') == None:
        default_users = {'autonomous': 'admin', 'database': 'system', 'db_free': 'system',
                         'pluggable': 'system',  'mysql': 'root', 'psql': 'postgres', 'opensearch': '', 'nosql': '', 
                         'none': ''}
        params['db_user'] = default_users[params['db_type']]
    if params.get('db_type')=='none':
        params.pop('db_user')     
        params.pop('db_password')     
    # shared_compute is valid only in compute deployment
    if params.get('db_install') == "shared_compute":
        if params.get('deploy_type')!='compute':
            params.pop('db_install')            


def language_rules():
    if params.get('language') != 'java' or params.get('deploy_type') == 'function':
        params.pop('java_framework')
        params.pop('java_vm')
        params.pop('java_version')
    elif params.get('java_framework') == 'helidon' and params.get('java_version') != '21':
        warning('Helidon only supports Java 17. Forcing Java version to 21')
        params['java_version'] = 21


def kubernetes_rules():
    if 'deploy_type' in params:
      params['deploy_type'] = longhand('deploy_type', {'oke': 'kubernetes', 'ci': 'container_instance'})


def vcn_rules():
    if 'subnet_ocid' in params:
        params['public_subnet_ocid'] = params['subnet_ocid']
        params['private_subnet_ocid'] = params['subnet_ocid']
        params.pop('subnet_ocid')
    if 'vcn_ocid' in params and 'public_subnet_ocid' not in params:
        error('-subnet_ocid or required for -vcn_ocid')
    elif 'vcn_ocid' not in params and 'public_subnet_ocid' in params:
        error('-vcn_ocid required for -subnet_ocid')
    
 
def ui_rules():
    params['ui_type'] = longhand('ui_type', {'reactjs': 'ReactJS'})
    if params.get('ui_type') == 'jsp':
        params['language'] = 'java'
        params['java_framework'] = 'tomcat'
    elif params.get('ui_type') == 'php':
        params['language'] = 'php'
    elif params.get('ui_type') == 'ruby':
        params['language'] = 'ruby'

def auth_token_rules():
    if params.get('deploy_type') in [ 'kubernetes', 'container_instance', 'function' ] and params.get('auth_token') is None:
        warning('-auth_token is not set. Will need to be set in env.sh')
        params['auth_token'] = TO_FILL


def compartment_rules():
    if params.get('compartment_ocid') is None:
        warning(
            '-compartment_ocid is not set. Components will be created in root compartment. Shame on you!')


def license_rules():
    license_model = os.getenv('LICENSE_MODEL')
    if license_model is not None:
        params['license_model'] = license_model
    params['license_model'] = longhand(
        'license_model', {'included': 'LICENSE_INCLUDED', 'byol': 'BRING_YOUR_OWN_LICENSE'})


def zip_rules():
    global output_dir, zip_dir
    output_dir = params['output_dir']
    if 'zip' in params:
        if 'group_name' in params:
             zip_dir = params['group_name']
        else:
             zip_dir = params['prefix']
        output_dir = "zip" + os.sep + params['zip'] + os.sep + zip_dir
        file_output('zip' + os.sep + params['zip'] + '.param', [json.dumps(params)])

def group_common_rules():
    if  params.get('group_common'):
        if params.get('group_common')=='none':
            params.pop('group_common')
        else:
            global a_group_common 
            a_group_common=params.get('group_common').split(',')


def shape_rules():
    if 'shape' in params:
        if params['shape']=='arm':
            params['shape'] = 'ampere' 
        if params.get('shape')=='freetier_amd':
            params['instance_shape'] = 'VM.Standard.E2.1.Micro'
            params['instance_shape_config_memory_in_gbs'] = 1
        if params.get('shape')=='ampere':
            params['instance_shape'] = 'VM.Standard.A1.Flex'
            params['instance_shape_config_memory_in_gbs'] = 8


def tls_rules():
    if params.get('tls')=='none':
        params.pop('tls')
    elif params.get('tls'):
        params['dns_name'] = TO_FILL
        if params.get('tls')=='new_http_01':
            params['certificate_email'] = TO_FILL
        elif params.get('tls')=='new_dns_01':
            params['certificate_email'] = TO_FILL
            params['dns_zone_name'] = TO_FILL
        elif params.get('tls')=='existing_ocid':
            params['dns_zone_name'] = TO_FILL
            params['certificate_ocid'] = TO_FILL
        elif params.get('tls')=='existing_dir':
            params['dns_zone_name'] = TO_FILL
            params['certificate_dir'] = TO_FILL


def apply_rules():
    zip_rules()
    group_common_rules()
    language_rules()
    kubernetes_rules()
    ui_rules()
    db_rules()
    vcn_rules()
    auth_token_rules()
    compartment_rules()
    license_rules()
    shape_rules()
    tls_rules()


def error(msg):
    errors.append(f'Error: {msg}')


def warning(msg):
    warnings.append(f'WARNING: {msg}')


def print_warnings():
    print(get_warnings())


def get_warnings():
    s = ''
    for warning in warnings:
        s += (f'{warning}\n')
    return s


def help():
    message = f'''
Usage: {script_name()} [OPTIONS]

starter.sh
   -apigw_ocid (optional)
   -atp_ocid (optional)
   -auth_token (optional)
   -bastion_ocid' (optional)
   -compartment_ocid (default tenancy_ocid)
   -database (default atp | dbsystem | pluggable | mysql | psql | opensearch | nosql | none )
   -db_ocid (optional)
   -db_password (mandatory)
   -db_user (default admin)
   -deploy (mandatory) compute | kubernetes | function | container_instance 
   -fnapp_ocid (optional)
   -group_common (optional) atp | database | mysql | psql | opensearch | nosql | fnapp | apigw | oke | jms 
   -group_name (optional)
   -java_framework (default helidon | springboot | tomcat)
   -java_version (default 21 | 17 | 11 | 8)
   -java_vm (default jdk | graalvm)  
   -kubernetes (default oke | docker) 
   -language (mandatory) java | node | python | dotnet | ords 
   -license (default included | byol )
   -mysql_ocid (optional)
   -psql_ocid (optional)
   -opensearch_ocid (optional)
   -nosql_ocid (optional)
   -oke_ocid (optional)
   -prefix (default starter)
   -public_subnet_ocid (optional)
   -private_subnet_ocid (optional)
   -shape (optional freetier)
   -ui (default html | reactjs | jet | angular | none) 
   -vcn_ocid (optional)
   -output_dir (optional)

'''
    if len(unknown_params) > 0:
        s = ''
        for unknown in unknown_params:
            s += f'{unknown} '
        message += f'Unknown parameter(s):{s}\n'
    if len(missing_params) > 0:
        s = ''
        for missing in missing_params:
            s += f'{missing} '
        message += f'Missing parameter(s):{s}\n'
    if len(illegal_params) > 0:
        s = ''
        for arg in illegal_params:
            s += f'Illegal value: "{illegal_params[arg]}" found for {arg}.  Permitted values: {allowed_values[arg]}\n'
        message += s
    if len(errors) > 0:
        s = ''
        for error in errors:
            s += f'{error}\n'
        message += s
    message += get_warnings()
    return message


def list_to_dict(a_list):
    it = iter(a_list)
    res_dct = dict(zip(it, it))
    return res_dct


def deprefix_keys(a_dict, prefix_length=1):
    return dict(map(lambda x: (x[0][prefix_length:], x[1]), a_dict.items()))


def missing_parameters(supplied_params, expected_params):
    expected_set = set(expected_params)
    supplied_set = set(supplied_params)
    for supplied in supplied_set:
        expected_set.discard(supplied)
    return list(expected_set)


def get_params():
    params = deprefix_keys({**default_options, **prog_arg_dict()})
    for key, value in rename_params.items():
        if params.get(key):
            params[value] = params[key]
            params.pop(key)
    return params


def git_params():
    keys = ['git_url', 'repository_name', 'oci_username']
    values = prog_arg_list()
    return dict(zip(keys, values))


def readme_contents():
    if 'group_name' in params:
        contents = ['''## OCI-Starter - Common Resources
                    
### License
                    
Check LICENSE file (Apache 2.0)                    

### Usage 

### Commands
- build_group.sh   : Build first the Common Resources (group_common), then other directories
- destroy_group.sh : Destroy other directories, then the Common Resources

- group_common
    - starter.sh build   : Create the Common Resources using Terraform
    - starter.sh destroy : Destroy the objects created by Terraform
    - env.sh                 : Contains the settings of the project

### Directories
- group_common/src : Sources files
    - terraform    : Terraform scripts (Command: plan.sh / apply.sh)

### After Build
- group_common_env.sh : File created during the build and imported in each application
- app1                : Directory with an application using "group_common_env.sh" 
- app2                : ...
...
    '''
                ]
    else:
        contents = ['''## OCI-Starter
### Usage 

### Commands
- starter.sh help    : Show the list of commands
- starter.sh build   : Build the whole program: Run Terraform, Configure the DB, Build the App, Build the UI
- starter.sh destroy : Destroy the objects created by Terraform
- starter.sh env     : Set the env variables in BASH Shell
                    
### Directories
- src           : Sources files
    - app       : Source of the Backend Application 
    - ui        : Source of the User Interface 
    - db        : SQL files of the database
    - terraform : Terraform scripts'''
                ]
        if params['deploy_type'] in [ 'compute', 'instance_pool' ]:
            contents.append(
                "    - compute   : Contains the deployment files to Compute")
        elif params['deploy_type'] == 'kubernetes':
            contents.append(
                "    - oke       : Contains the deployment files to Kubernetes")

    contents.append("\nHelp (Tutorial + How to customize): https://www.ocistarter.com/help")

    contents.append('\n### Next Steps:')
    if TO_FILL in params.values():
        if 'group_name' in params:
            contents.append("- Edit the file group_common/env.sh. Some variables need to be filled:")
        else:
            contents.append("- Edit the file env.sh. Some variables need to be filled:")
        contents.append("```")
        for param, value in params.items():
            if value == TO_FILL:
                contents.append(
                    f'export {get_tf_var(param)}="{params[param]}"')
        contents.append("```")
    contents.append("\n- Run:")
    if 'group_name' in params:
        contents.append("  # Build first the group common resources (group_common), then other directories")
        contents.append(f"  cd {params['group_name']}")
        contents.append("  ./build_group.sh")       
    else:
        contents.append(f"  cd {params['prefix']}")
        contents.append("  ./starter.sh build")
    return contents

def is_param_default_value(name):
    return params.get(name) == default_options.get('-'+name)

def env_param_list():
    env_params = list(params.keys())
    exclude = ['mode', 'zip', 'prefix', 'shape', 'params', 'output_dir']
    if params.get('language') != 'java' or 'group_name' in params:
        exclude.extend(['java_vm', 'java_framework', 'java_version'])
    if 'group_name' in params:
        exclude.extend(['ui_type', 'db_type', 'language', 'deploy_type', 'db_user', 'group_name'])
    else:
        exclude.append('group_common')
    if is_param_default_value('infra_as_code'):
        exclude.append('infra_as_code')        

    print(exclude)
    for x in exclude:
        if x in env_params:
            env_params.remove(x)
    return env_params

def env_sh_contents():
    env_params = env_param_list()
    print(env_params)
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M-%S-%f")
    contents = ['#!/bin/bash']
    contents.append(
        'PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )')
    contents.append(f'export BIN_DIR=$PROJECT_DIR/bin')
    contents.append('')
    contents.append('# Env Variables')
    if 'group_name' in params:
        prefix = params["group_name"]
        contents.append(f'export TF_VAR_group_name="{prefix}"')
    else:
        prefix = params["prefix"]
    contents.append(f'export TF_VAR_prefix="{prefix}"')
    contents.append('')

    group_common_contents = []
    for param in env_params:
        if param.endswith("_ocid") or param in ["db_password", "auth_token", "license"]:
            tf_var_comment(group_common_contents, param)
            group_common_contents.append(f'export {get_tf_var(param)}="{params[param]}"')
        else:
            tf_var_comment(contents, param)
            contents.append(f'export {get_tf_var(param)}="{params[param]}"')
    contents.append('')
    if params.get('compartment_ocid') == None:
        contents.append('# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx')       
    for s in group_common_contents:
        contents.append(s)

    contents.append('')
    contents.append("if [ -f $PROJECT_DIR/../group_common_env.sh ]; then")      
    contents.append("  . $PROJECT_DIR/../group_common_env.sh")      
    contents.append("elif [ -f $PROJECT_DIR/../../group_common_env.sh ]; then")      
    contents.append("  . $PROJECT_DIR/../../group_common_env.sh")      
    contents.append("elif [ -f $HOME/.oci_starter_profile ]; then")
    contents.append("  . $HOME/.oci_starter_profile")
    # contents.append("else")      
    # contents.append('')
    # contents.append('  # API Management')
    # contents.append('  # export APIM_HOST=xxxx-xxx.adb.region.oraclecloudapps.com')
    # contents.append('')
    # if params.get('instance_shape') == None:   
    #    contents.append('  # Compute Shape')
    #    contents.append('  # export TF_VAR_instance_shape=VM.Standard.E4.Flex')
    #    contents.append('')
    # contents.append('  # Landing Zone')
    # contents.append('  # export TF_VAR_lz_appdev_cmp_ocid=$TF_VAR_compartment_ocid')
    # contents.append('  # export TF_VAR_lz_database_cmp_ocid=$TF_VAR_compartment_ocid')
    # contents.append('  # export TF_VAR_lz_network_cmp_ocid=$TF_VAR_compartment_ocid')
    # contents.append('  # export TF_VAR_lz_security_cmp_ocid=$TF_VAR_compartment_ocid')
    contents.append("fi")      
    contents.append('')
    contents.append('# Creation Details')
    contents.append(f'export OCI_STARTER_CREATION_DATE={timestamp}')
    contents.append(f'export OCI_STARTER_VERSION=2.0')
    contents.append(f'export OCI_STARTER_PARAMS="{params["params"]}"')
    contents.append('')
    contents.append(
        '# Get other env variables automatically (-silent flag can be passed)')
    contents.append('. $BIN_DIR/auto_env.sh $1')
    return contents


def tf_var_comment(contents, param):
    comments = {
        'auth_token': ['See doc: https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm'],
        'db_password': ['Min length 12 characters, 2 lowercase, 2 uppercase, 2 numbers, 2 special characters. Ex: LiveLab__12345', 'If not filled, it will be generated randomly during the first build.'],
        'license': ['BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED'],
        'certificate_ocid': ['OCID of the OCI Certificate','If the certificate is not imported in OCI, use instead TF_VAR_certificate_dir=<directory where the certificate resides>', 'export TF_VAR_certificate_dir="__TO_FILL__"']
    }.get(param)
    if comments is not None:
        b=True
        for comment in comments:
            if b:
                b=False
                contents.append(f'# {get_tf_var(param)} : {comment}')
            else:
                contents.append(f'#   {comment}')



def write_env_sh():
    output_path = output_dir + os.sep + 'env.sh'
    file_output(output_path, env_sh_contents())
    os.chmod(output_path, 0o755)


def write_readme():
    output_path = output_dir + os.sep + 'README.md'
    file_output(output_path, readme_contents())


def file_output(file_path, contents):
    output_file = open(file_path, "w")
    output_file.writelines('%s\n' % line for line in contents)
    output_file.close()


## COPY FILES ###############################################################
def copy_basis(basis_dir=BASIS_DIR):
    print( "output_dir="+output_dir )
    copy_tree(basis_dir, output_dir)

def output_replace(old_string, new_string, filename):
    # Safely read the input filename using 'with'
    path = output_dir + os.sep + filename
    if os.path.exists(path):
        with open(path) as f:
            s = f.read()
            if old_string not in s:
                print('"{old_string}" not found in {filename}.'.format(**locals()))
                return

        # Safely write the changed content, if found in the file
        with open(path, 'w') as f:
            s = s.replace(old_string, new_string)
            f.write(s)

def append_file(file1, file2):
    print("append " + file2)
    # opening first file in append mode and second file in read mode
    f1 = open(file1, 'a+')
    f2 = open(file2, 'r')
    # appending the contents of the second file to the first file
    f1.write('\n\n')
    f1.write(f2.read())
    f1.close()
    f2.close()                

def cp_terraform(file1, file2=None, file3=None):
    print("cp_terraform " + file1)
    shutil.copy2("option/terraform/"+file1, output_dir + "/src/terraform")

    # Append a second file
    if file2 is not None:
        append_file( output_dir + "/src/terraform/"+file1, "option/terraform/"+file2 )

    # Append a third file
    if file3 is not None:
        append_file( output_dir + "/src/terraform/"+file1, "option/terraform/"+file3 )

def cp_terraform_existing( param_name, file1, file2=None, file3=None):
    file_name = file1
    if param_name in params:
        file_name = file1.replace(".j2.", "_existing.j2.")
    print("cp_terraform_existing: " + file_name)
    shutil.copy2("option/terraform/"+file1, output_dir + "/src/terraform/"+file_name)

    # Append a second file
    if file2 is not None:
        append_file( output_dir + "/src/terraform/"+file_name, "option/terraform/"+file2 )

    # Append a third file
    if file3 is not None:
        append_file( output_dir + "/src/terraform/"+file_name, "option/terraform/"+file3 )


def output_copy_tree(src, target):
    copy_tree(src, output_dir + os.sep + target)

def output_move(src, target):
    shutil.move(output_dir + os.sep + src, output_dir + os.sep + target)

def output_mkdir(src):
    os.mkdir(output_dir+ os.sep + src)

def output_remove(src):
    os.remove(output_dir + os.sep + src)

def output_rm_tree(src):
    shutil.rmtree(output_dir + os.sep + src)
 
def cp_dir_src_db(db_family):
    print("cp_dir_src_db "+db_family)
    output_copy_tree("option/src/db/"+db_family, "src/db")

def output_replace_db_node_count():
    if params.get('db_node_count')!="2":
       output_replace('##db_node_count##', "1", "src/terraform/dbsystem.j2.tf")
       output_replace('##db_edition##', "ENTERPRISE_EDITION", "src/terraform/dbsystem.j2.tf")
       output_replace('##storage_management##', "LVM", "src/terraform/dbsystem.j2.tf")
       output_replace('##cpu_core_count##', "1", "src/terraform/dbsystem.j2.tf")
    else:
       output_replace('##db_node_count##', "2", "src/terraform/dbsystem.j2.tf")
       output_replace('##db_edition##', "ENTERPRISE_EDITION_EXTREME_PERFORMANCE", "src/terraform/dbsystem.j2.tf")
       output_replace('##storage_management##', "ASM", "src/terraform/dbsystem.j2.tf")
       output_replace('##cpu_core_count##', "4", "src/terraform/dbsystem.j2.tf")
       output_copy_tree("option/src/db/rac", "src/db")
       output_move("src/db/deploy_db_node.sh", "bin/deploy_db_node.sh")
       if params['language'] == "java" and params['java_framework'] == "springboot":
           output_copy_tree("option/src/app/java_springboot_rac", "src/app")
       if params['ui_type'] == "html":
           output_copy_tree("option/src/ui/html_rac", "src/ui" )    

# Copy the terraform for APIGW
def cp_terraform_apigw(append_tf):
    if params['language'] == "ords":
        app_url = "${local.ords_url}/starter/module/$${request.path[pathname]}"
    elif params['language'] == "apex":
        app_url = "${local.ords_url}/r/app_dept/dept/$${request.path[pathname]}"
    elif params['language'] == "java" and params['java_framework'] == "tomcat":
        app_url = "http://${local.apigw_dest_private_ip}:8080/starter-1.0/$${request.path[pathname]}"
    else:
        app_url = "http://${local.apigw_dest_private_ip}:8080/$${request.path[pathname]}" 

    cp_terraform_existing("apigw_ocid", "apigw.j2.tf", append_tf)
    if 'apigw_ocid' in params:
        output_replace('##APP_URL##', app_url,"src/terraform/apigw_existing.j2.tf")
    else:
        output_replace('##APP_URL##', app_url, "src/terraform/apigw.j2.tf")    

#----------------------------------------------------------------------------
# Create Directory (shared for group_common and output)
def create_dir_shared():
    copy_basis()
    write_env_sh()
    write_readme()

    # -- Infrastructure As Code ---------------------------------------------
    # Default state local
    if params.get('infra_as_code') == "resource_manager":
        # Nothing to copy
        print("resource_manager")
    elif params.get('infra_as_code') == "terraform_object_storage":
        output_copy_tree("option/infra_as_code/terraform_object_storage", "src/terraform")
    else:
        output_copy_tree("option/infra_as_code/terraform_local", "src/terraform")

    # -- Network ------------------------------------------------------------
    cp_terraform_existing("vcn_ocid", "network.j2.tf")

    # -- Bastion ------------------------------------------------------------
    # Currently limited to provision the database ? 
    # XXXX In the future maybe as build machine ?
    if params.get('db_install') == "shared_compute" or 'bastion_ocid' in params or params.get('db_type')!='none':
        cp_terraform_existing("bastion_ocid", "bastion.j2.tf")

#----------------------------------------------------------------------------
# Create Output Directory
def create_output_dir():
    create_dir_shared()

    # -- APP ----------------------------------------------------------------
    if params['language'] == "none":
        output_rm_tree("src/app")
    else:
        if params.get('deploy_type') == "function":
            app = "fn/fn_"+params['language']
        else:
            app = params['language']

        if params['db_type'] == "autonomous" or params['db_type'] == "database" or params['db_type'] == "pluggable" or params['db_type'] == "db_free":
            db_family = "oracle"
            db_family_type = "sql"
        elif params['db_type'] == "mysql":
            db_family = "mysql"
            db_family_type = "sql"
        elif params['db_type'] == "psql":
            db_family = "psql"
            db_family_type = "sql"
        elif params['db_type'] == "opensearch":
            db_family = "opensearch"
            db_family_type = "other"
        elif params['db_type'] == "nosql":
            db_family = "nosql"
            db_family_type = "other"
        elif params['db_type'] == "none":
            db_family = "none"
            db_family_type = "other"
        params['db_family'] = db_family    
        params['db_family_type'] = db_family_type

        # Function Common
        if params.get('deploy_type') == "function":
            output_copy_tree("option/src/app/fn/fn_common", "src/app")
         
        # Generic version for Oracle DB
        if os.path.exists("option/src/app/"+app):
            output_copy_tree("option/src/app/"+app, "src/app")

        if params.get('deploy_type') != "function" and params['language'] == "java":
            # Java Framework
            app = "java_" + params['java_framework']
            output_copy_tree("option/src/app/"+app, "src/app")

        # Overwrite the generic version (ex for mysql)
        family_dir = app+"_"+db_family
        print("family_dir="+family_dir)
        if os.path.exists("option/src/app/"+family_dir):
            output_copy_tree("option/src/app/"+family_dir, "src/app")

        # Overwrite the family type version (ex for sql)
        family_type_dir = app+"_"+db_family_type
        print("family_type_dir="+family_type_dir)
        if os.path.exists("option/src/app/"+family_type_dir):
            output_copy_tree("option/src/app/"+family_type_dir, "src/app")

        if params['language'] == "java":
            # FROM container-registry.oracle.com/graalvm/jdk:21
            # FROM openjdk:21
            # FROM openjdk:21-jdk-slim
            if os.path.exists(output_dir + "/src/app/Dockerfile"):
                if params['java_vm'] == "graalvm":
                    output_replace('##DOCKER_IMAGE##', 'container-registry.oracle.com/graalvm/jdk:21', "src/app/Dockerfile")
                else:
                    output_replace('##DOCKER_IMAGE##', 'openjdk:21-jdk-slim', "src/app/Dockerfile")

    # -- User Interface -----------------------------------------------------
    if params.get('ui_type') == "none":
        print("No UI")
        output_rm_tree("src/ui")
    elif params.get('ui_type') == "api": 
        print("API Only")
        output_rm_tree("src/ui")   
        if params.get('deploy_type') in [ 'compute', 'instance_pool' ]:
            cp_terraform_apigw("apigw_compute_append.tf")          
    else:
        ui_lower = params.get('ui_type').lower()
        output_copy_tree("option/src/ui/"+ui_lower, "src/ui")

    # -- Deployment ---------------------------------------------------------
    if params.get('deploy_type') == "hpc":
        # remove normal shared terraform file
        output_terraform_dir = output_dir + os.sep + "src/terraform"
        for fname in os.listdir(output_terraform_dir):
            if fname.endswith(".tf"):
                os.remove(os.path.join(output_terraform_dir, fname))
        output_copy_tree("../oci-hpc", "src/terraform")
        # remove the original variables files
        output_remove( "src/terraform/variables.tf" )
        # replace with a prefilled one
        cp_terraform("hpc_variables.tf")
    elif params.get('deploy_type') == "datascience":
        cp_terraform("datascience.tf")
    elif params['language'] != "none":
        if params.get('deploy_type') == "kubernetes":
            if params.get('oke_type') == "managed":
                cp_terraform_existing( "oke_ocid", "oke.j2.tf")
            else:
                cp_terraform_existing( "oke_ocid", "oke_virtual_node.j2.tf")
                output_move("src/terraform/oke_virtual_node.j2.tf", "src/terraform/oke.j2.tf")
            output_mkdir("src/oke")
            output_copy_tree("option/oke", "src/oke")
            output_move("src/oke/oke_deploy.sh", "bin/oke_deploy.sh")
            output_move("src/oke/oke_destroy.sh", "bin/oke_destroy.sh")

            output_replace('##PREFIX##', params["prefix"], "src/app/app.yaml")
            output_replace('##PREFIX##', params["prefix"], "src/ui/ui.yaml")
            output_replace('##PREFIX##', params["prefix"], "src/oke/ingress-app.j2.yaml")
            output_replace('##PREFIX##', params["prefix"], "src/oke/ingress-ui.j2.yaml")

        elif params.get('deploy_type') == "function":
            cp_terraform_existing("fnapp_ocid", "function.j2.tf")
            if 'fnapp_ocid' not in params:
                cp_terraform("log_group.tf")
            if params['language'] == "ords":
                apigw_append = "apigw_fn_ords_append.tf"
            else:
                apigw_append = "apigw_fn_append.tf"
            cp_terraform_existing("apigw_ocid", "apigw.j2.tf", apigw_append)

        elif params.get('deploy_type') in [ 'compute', 'instance_pool' ]:
            cp_terraform_existing("compute_ocid", "compute.j2.tf")
            output_mkdir("src/compute")
            output_copy_tree("option/compute", "src/compute")
            if params.get('deploy_type') == 'instance_pool':
                cp_terraform("instance_pool.j2.tf")            
            elif params.get('tls') == 'existing_dir':
                output_copy_tree("option/tls/compute_existing_dir", "src/tls")
            elif params.get('tls') == 'new_http_01':
                output_copy_tree("option/tls/new_http_01", "src/tls")
            elif params.get('tls') == 'existing_ocid':
                cp_terraform_apigw("apigw_compute_append.tf")   

        elif params.get('deploy_type') == "container_instance":
            cp_terraform("container_instance.j2.tf")
            if 'group_common' not in params:
                cp_terraform("container_instance_policy.tf")

            # output_mkdir src/container_instance
            output_copy_tree("option/container_instance", "bin")
            cp_terraform_apigw("apigw_ci_append.tf")          

    if params.get('tls'):
        cp_terraform("tls.j2.tf")
        if params.get('deploy_type') == 'kubernetes' and params.get('tls') != 'new_http_01':
            cp_terraform_apigw("apigw_kubernetes_tls_append.tf")   

    if os.path.exists(output_dir + "/src/app/openapi_spec_append.yaml"):
        append_file( output_dir + "/src/app/openapi_spec.yaml", output_dir + "/src/app/openapi_spec_append.yaml")
        os.remove( output_dir + "/src/app/openapi_spec_append.yaml" )

    # -- Database ----------------------------------------------------------------
    if params.get('db_type') != "none":
        cp_terraform("output.tf")
        output_mkdir("src/db")

        cp_dir_src_db(db_family)
        if params.get('db_type') == "autonomous":
            cp_terraform_existing("atp_ocid", "atp.j2.tf")

        if params.get('db_type') == "database":
            cp_terraform_existing("db_ocid", "dbsystem.j2.tf")
            if 'db_ocid' not in params:
                output_replace_db_node_count()

        if params.get('db_type') == "pluggable":
            cp_terraform_existing("pdb_ocid", "dbsystem_pluggable.j2.tf")

        if params.get('db_type') == "db_free":
            cp_terraform("db_free.j2.tf")
            output_copy_tree("option/src/db/db_free", "src/db")
            output_move("src/db/deploy_db_node.sh", "bin/deploy_db_node.sh")

        if params.get('db_type') == "mysql":
            if params.get('db_install') == "shared_compute":
               cp_terraform("mysql_shared_compute.tf")   
               output_copy_tree("option/src/db/mysql_shared_compute", "src/db")  
               output_move("src/db/deploy_db_node.sh", "bin/deploy_db_node.sh")       
            else:
                cp_terraform_existing("mysql_ocid", "mysql.j2.tf")

        if params.get('db_type') == "psql":
            cp_terraform_existing("psql_ocid", "psql.j2.tf")

        if params.get('db_type') == "opensearch":
            cp_terraform_existing("opensearch_ocid", "opensearch.j2.tf")

        if params.get('db_type') == "nosql":
            cp_terraform_existing("nosql_ocid", "nosql.j2.tf")

    if os.path.exists(output_dir + "/src/app/db"):
        allfiles = os.listdir(output_dir + "/src/app/db")
        # iterate on all files to move them to destination folder
        for f in allfiles:
            src_path = os.path.join("src/app/db", f)
            dst_path = os.path.join("src/db", f)
            output_move(src_path, dst_path) 
        os.rmdir(output_dir + "/src/app/db")         


#----------------------------------------------------------------------------
# Create group_common Directory
def create_group_common_dir():
    create_dir_shared()

    # -- APP ----------------------------------------------------------------
    output_copy_tree("option/src/app/group_common", "src/app")
    os.remove(output_dir + "/src/app/app.j2.yaml")

    # -- User Interface -----------------------------------------------------
    output_rm_tree("src/ui")

    # -- Common -------------------------------------------------------------
    if "atp" in a_group_common:
        cp_terraform_existing("atp_ocid", "atp.j2.tf")

    if "database" in a_group_common:
        cp_terraform_existing("db_ocid", "dbsystem.j2.tf")
        if 'db_ocid' not in params:
            output_replace_db_node_count()

    if "db_free" in a_group_common:
        cp_terraform("db_free.j2.tf")
        output_copy_tree("option/src/db/db_free", "src/db")
        output_move("src/db/deploy_db_node.sh", "bin/deploy_db_node.sh")            

    if "mysql" in a_group_common:
        cp_terraform_existing("mysql_ocid", "mysql.j2.tf")

    if "psql" in a_group_common:
        cp_terraform_existing("psql_ocid", "psql.j2.tf")

    if "opensearch" in a_group_common:
        cp_terraform_existing("opensearch_ocid", "opensearch.j2.tf")

    if "nosql" in a_group_common:
        cp_terraform_existing("nosql_ocid", "nosql.j2.tf")

    if 'oke' in a_group_common:
        cp_terraform_existing("oke_ocid", "oke.j2.tf")
        if 'oke_ocid' not in params:
            shutil.copy2("option/oke/oke_destroy.sh", output_dir +"/bin")

    if 'fnapp' in a_group_common:
        cp_terraform_existing("fnapp_ocid", "function.j2.tf")
        if 'fnapp_ocid' not in params:
            cp_terraform("log_group.tf")

    if 'apigw' in a_group_common:
        cp_terraform_existing("apigw_ocid", "apigw.j2.tf")
        if 'apigw_ocid' not in params:
            cp_terraform("log_group.tf")

    if 'jms' in a_group_common:
        cp_terraform_existing("jms_ocid", "jms.j2.tf")
        if 'jms_ocid' not in params:
            cp_terraform("log_group.tf")

    if 'compute' in a_group_common:
        cp_terraform_existing("compute_ocid", "compute.j2.tf")

    # Container Instance Common
    cp_terraform("container_instance_policy.tf")

    allfiles = os.listdir(output_dir)
    allfiles.remove('README.md')
    # Create a group directory
    output_mkdir('group_common')
    # iterate on all files to move them to 'group_common'
    for f in allfiles:
        os.rename(output_dir + os.sep + f, output_dir + os.sep + 'group_common' + os.sep + f)

    output_copy_tree("option/group", ".")
    
#----------------------------------------------------------------------------

jinja2_db_params = {
    "oracle": { 
        "pomGroupId": "com.oracle.database.jdbc",
        "pomArtifactId": "ojdbc8",
        "pomVersion": "21.11.0.0",
        "jdbcDriverClassName": "oracle.jdbc.OracleDriver",
        "dbName": "Oracle",

    },
    "mysql": { 
        "pomGroupId": "mysql",
        "pomArtifactId": "mysql-connector-java",
        "pomVersion": "8.0.31",
        "jdbcDriverClassName": "com.mysql.cj.jdbc.Driver",
        "dbName": "MySQL"
    },
    "psql": { 
        "pomGroupId": "org.postgresql",
        "pomArtifactId": "postgresql",
        "pomVersion": "42.7.0",
        "jdbcDriverClassName": "org.postgresql.Driver",
        "dbName": "PostgreSQL"
    },
    "opensearch": { 
        "pomGroupId": "org.opensearch.driver",
        "pomArtifactId": "opensearch-sql-jdbc",
        "pomVersion": "1.4.0.1",
        "jdbcDriverClassName": "org.opensearch.jdbc.Driver",
        "dbName": "OpenSearch"
    },
    "nosql": {
        "dbName": "NoSQL"
    },
    "none": {
        "dbName": "No Database"
    }
}

def jinja2_replace_template():
    db_param = jinja2_db_params.get( params.get('db_family') )
    if db_param is None:  
        template_param = params
    else:   
        template_param = {**params, **db_param}

    for subdir, dirs, files in os.walk(output_dir):
        for filename in files:    
            if filename.find('.j2.')>0 or filename.endswith('.j2'):
                output_file_path = os.path.join(subdir, filename.replace(".j2", ""))
                if os.path.isfile(output_file_path): 
                    print(f"J2 - Skipping - destination file already exists: {output_file_path}") 
                else:
                    environment = Environment(loader=FileSystemLoader([subdir,"option/src/j2_macro"]))
                    template = environment.get_template(filename)
                    db_param = jinja2_db_params.get( params.get('db_family') )
                    content = template.render( template_param )
                    with open(output_file_path, mode="w", encoding="utf-8") as output_file:
                        output_file.write(content)
                        print(f"J2 - Wrote {output_file_path}")
                    # Give executable to .sh files
                    if filename.endswith('.sh'):
                        st = os.stat(output_file_path)
                        os.chmod(output_file_path, st.st_mode | stat.S_IEXEC)        
                os.remove(os.path.join(subdir, filename))                
            if filename.endswith('_refresh.sh'):      
                os.remove(os.path.join(subdir, filename))   

#----------------------------------------------------------------------------

# the script
print(title(script_name()))

script_dir = os.getcwd()

params = get_params()
mode = get_mode()
unknown_params = missing_parameters(allowed_options(), prog_arg_dict().keys())
illegal_params = check_values()
dash_params={f'-{k}': v for k, v in params.items()}
if 'group_name' in params:
  missing_params = missing_parameters(dash_params.keys(), mandatory_options(GROUP))
else:  
  missing_params = missing_parameters(dash_params.keys(), mandatory_options(mode))

if len(unknown_params) > 0 or len(illegal_params) > 0 or len(missing_params) > 0:
    mode = ABORT

warnings = []
errors = []

if mode == CLI:
    if os.path.isdir(output_dir):
        print("Output dir exists already.")
        mode = ABORT
    else:
        save_params()
        apply_rules()
        if len(errors) > 0:
            mode = ABORT
        else:
            print_warnings()

if mode == ABORT:
    print(help())
    exit(1)

print(f'Mode: {mode}')
print(f'params: {params}')

# -- Copy Files -------------------------------------------------------------
output_dir_orig = output_dir

# Create a group
if 'group_name' in params:
    create_group_common_dir()
    jinja2_replace_template()

# Add parameters to the creation if the project is to be used with a group
if 'group_common' in params:
    # For a new group, create the first application in a subdir
    if 'group_name' in params:
        del params['group_name']    
        output_dir = output_dir + os.sep + params['prefix']
    # The application will use the Common Resources created by group_name above.
    # del params['group_common']
    params['vcn_ocid'] = TO_FILL
    params['public_subnet_ocid'] = TO_FILL
    params['private_subnet_ocid'] = TO_FILL
    # Use a bastion only for the database
    if params.get('db_type')!='none':
        params['bastion_ocid'] = TO_FILL
    to_ocid = { "atp": "atp_ocid", "database": "db_ocid", "mysql": "mysql_ocid", "psql": "psql_ocid", "opensearch": "opensearch_ocid", "nosql": "nosql_ocid", "oke": "oke_ocid", "fnapp": "fnapp_ocid", "apigw": "apigw_ocid", "jms": "jms_ocid", "compute": "compute_ocid"}
    for x in a_group_common:
        if x in to_ocid:
            ocid = to_ocid[x]
            params[ocid] = TO_FILL

if 'deploy_type' in params:
    create_output_dir()
    jinja2_replace_template()

# -- Done --------------------------------------------------------------------
title("Done")
print("Directory "+output_dir+" created.")

# -- Post Creation -----------------------------------------------------------

if mode == GIT:
    print("GIT mode currently not implemented.")
    # git config --local user.email "test@example.com"
    # git config --local user.name "${OCI_USERNAME}"
    # git add .
    # git commit -m "added latest files"
    # git push origin main

elif "zip" in params:
    # The goal is to have a file that when uncompressed create a directory prefix.
    shutil.make_archive("zip"+os.sep+params['zip'], format='zip',root_dir="zip"+os.sep+params['zip'], base_dir=zip_dir)
    print("Zip file created: zip"+os.sep+params['zip']+".zip")
else:
    print()
    readme= output_dir_orig + os.sep + "README.md"
    with open(readme, 'r') as fin:
        print(fin.read())

