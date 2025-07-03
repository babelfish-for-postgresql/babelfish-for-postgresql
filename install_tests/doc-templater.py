import sys
import re
import glob

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

def load_document_template():
    with open("doc-template.md") as initial_template_file:
        return initial_template_file.readlines()

def load_step(step_path):
    step_content = []
    with open(step_path) as step_file:
        step_content = step_file.readlines()
    starts_with=re.search("^#!", step_content[0])
    if starts_with:
        step_content.pop(0)
    return step_content

def parse_document_template(steps):
    parsed_document = []
    document_template = load_document_template()
    for document_line in document_template:
        step = is_line_a_template_markup(document_line)
        if step:
            parsed_document = parsed_document + load_step(steps[step])
        else:
            parsed_document.append(document_line)

    return parsed_document

def write_document(distro, document_output):
    output_file_format = "output/{distro}/compiling-babelfish-from-source.md"
    with open(output_file_format.format(distro = distro), 'w') as output_file:
        output_file.writelines(document_output)
  


steps = load_steps(distro)

document_output = parse_document_template(steps)

write_document(distro, document_output)

