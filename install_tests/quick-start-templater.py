import sys
import re
import glob

distro=sys.argv[1]
distro_id=sys.argv[2]

def get_step_function_name(step_path):
    path_parts = step_path.split("/")    
    return path_parts[-1].replace("-", "_")

def load_custom_installation_steps():
    custom_steps = glob.glob("distros/{distro}/steps/*".format(distro=distro))
    steps = {}
    for step_path in custom_steps:
        step_name = get_step_function_name(step_path)
        steps[step_name] = step_path
    return steps

def load_prerequisites_paths():    
    return [
        "distros/{distro}/steps/core-prerequisites".format(distro = distro),
        "distros/{distro}/steps/extension-prerequisites".format(distro = distro)
    ]

def parse_prerequesite(path, function_name):

    prerequisite_content = []
    with open(path) as prerequisites_file:
        prerequisite_content = prerequisites_file.readlines()
    parsed_content=[ "{name}(){{\n".format(name=function_name) ]
        
    if re.search("^#!", prerequisite_content[0]):
        prerequisite_content.pop(0)

    for content_line in prerequisite_content:
        command_line = content_line
        if re.search("^sudo ", content_line): # is chaning user
            command_line = content_line[5:]
        parsed_content.append( "  " + command_line)
    
    parsed_content.append("}\n")
    return parsed_content   

def generate_prerequisites():
    prerequisites_steps = load_custom_installation_steps()
    prerequisite_script = [ "#!/bin/sh\n" ]

    for function_name, prerequisite_path in prerequisites_steps.items():
        parsed_prerequisite = parse_prerequesite(prerequisite_path, function_name)        
        prerequisite_script = prerequisite_script + parsed_prerequisite


    return prerequisite_script

def write_prerequisites(prerequisites):
    pre_requesite_script_path = "output/quickinstall/prerequisites/{distro_id}".format(distro=distro, distro_id=distro_id)
    with open(pre_requesite_script_path, 'w') as output_file:
        output_file.writelines(prerequisites)

prerequisites = generate_prerequisites()

write_prerequisites(prerequisites)

