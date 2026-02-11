import sys
import glob
import re

distro=sys.argv[1]

def get_step_name(step_path):
    path_parts = step_path.split("/")
    return path_parts[-1]

def load_steps(distro):
    common_steps = glob.glob("steps/**")

    steps = {}
    for step_path in common_steps:
        step_name = get_step_name(step_path)
        steps[step_name] = step_path

    custom_steps = glob.glob("distros/{distro}/steps/*".format(distro=distro))

    for step_path in custom_steps:
        step_name = get_step_name(step_path)
        steps[step_name] = step_path

    return steps

def is_line_a_template_markup(line):
    match = re.search("^{{ (.+) }}", line)
    if match:
        return match.group(1)
    else:
        return None

def load_dockerfile_template():
    with open("Dockerfile.template") as initial_template_file:
        return initial_template_file.readlines()

def load_step(step_path):
    step_content = []
    step_name = get_step_name(step_path)
    with open(step_path) as step_file:
        step_content = step_file.readlines()
    starts_with=re.search("^#!", step_content[0])
    if starts_with:
        step_content.pop(0)
    
    last_line_index = len(step_content) - 1

    is_previous_command_multiline = False

    parsed_step = []
    
    for content_tuple in enumerate(step_content):
        line_index = content_tuple[0]
        content_line = content_tuple[1]
        dockerfile_lile = content_line
        if is_previous_command_multiline: # is multilining
            dockerfile_lile = content_line
        elif len(content_line.strip()) == 0: # is empty
            dockerfile_lile = content_line
        elif re.search("^sudo apt-get install -y ", content_line): # is installing ubuntu packages
            dockerfile_lile = "RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends" + dockerfile_lile[23:]
        elif re.search("^sudo su ", content_line): # is chaning user
            dockerfile_lile = "USER " + dockerfile_lile[7:]
        elif re.search("^sudo", content_line): # is running with sudo
            dockerfile_lile = "RUN " + dockerfile_lile[5:]
        elif re.search("^cd", content_line): # is moving between paths
            cd_path = dockerfile_lile[3:]
            if re.search("^/", cd_path): # is an absolute path
                update_current_workdir(cd_path)

            elif re.search("\\.\\.", cd_path):  # is going up one level
                workdir_parts = current_workdir.split("/")
                relative_parts = cd_path.split("/")
                for relative_path in relative_parts:    
                    if re.search("^\\.\\.", relative_path):
                        workdir_parts = workdir_parts[:-1]
                    else:
                        workdir_parts.append(relative_path)

                update_current_workdir("/".join(workdir_parts))
            else: # is relative path
                update_current_workdir(current_workdir + "/" + cd_path)
            dockerfile_lile = "WORKDIR " + current_workdir
        elif step_name == "start-database" and line_index == last_line_index:
            line_parts = content_line.split(" ")
            dockerfile_lile = 'CMD ["' + '", "'.join(line_parts) + '" ]'
        else:
            dockerfile_lile = "RUN " + content_line
        
        parsed_step.append(dockerfile_lile)

        if re.search("\\\\\n$", content_line):  # matches if there is line is ending with \
            is_previous_command_multiline = True
        else:
            is_previous_command_multiline = False

    return parsed_step

def is_workdir_line(line):
    match = re.search("^WORKDIR (.+)", line)
    if match:
        return match.group(1)
    else:
        return None

def update_current_workdir(workir):
    global current_workdir 
    current_workdir = workir

def parse_dockerfile_template(steps):
    parsed_dockerfile = []
    dockerfile_template = load_dockerfile_template()
    for dockerfile_line in dockerfile_template:
        workir = is_workdir_line(dockerfile_line)
        if workir:
            update_current_workdir(workir)

        step = is_line_a_template_markup(dockerfile_line)
        if step:
            parsed_dockerfile = parsed_dockerfile + load_step(steps[step])
        else:
            parsed_dockerfile.append(dockerfile_line)

    return parsed_dockerfile

def write_dockerfile(distro, dockerfile_output):
    dockerfile_file_format = "distros/{distro}/Dockerfile"
    with open(dockerfile_file_format.format(distro = distro), 'w') as output_file:
        output_file.writelines(dockerfile_output)

def get_distro_image(distro):
    distro_parts = distro.split(".")
    distro_name = distro_parts[0]
    distro_version = ".".join(distro_parts[1:])
    return distro_name + ":" + distro_version

def get_from_line(distro):
    distro_image = get_distro_image(distro)
    return "FROM {image}".format(image = distro_image)

current_workdir="/"

steps = load_steps(distro)

dockerfile = parse_dockerfile_template(steps)

dockerfile = [ get_from_line(distro) ] + dockerfile

write_dockerfile(distro, dockerfile)
