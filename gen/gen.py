import sys
import os
import yaml
import jinja2
import re


def gen(inputyaml):
    print("Input file: {}".format(inputyaml))

    fileyaml = open(inputyaml, 'r')
    yamldata = yaml.load(fileyaml, Loader=yaml.FullLoader)

    #print(yamldata)

    
    # TODO:  need a comprehensive way to validate
    #  the YAML file instead of individual checks
    #  like below.
    if not "name" in yamldata:
        print("ERROR: Missing 'name' in YAML.")
        return
    else:
        name = yamldata["name"]
        if not re.match("^[A-Za-z0-9_-]+$", name):
            print("ERROR: Invalid character in name")
            return 

    #impCompList = yamldata["import"].keys()
    #expCompList = yamldata["export"].keys()

        
    jenv = jinja2.Environment(
        loader=jinja2.FileSystemLoader('templates'),
        trim_blocks=True,
        lstrip_blocks=True
    )

    template = jenv.get_template("esmFldsExchange.F90.jinja")
    out = template.render(name=name, yaml=yamldata)
    
    print("Output:\n\n{}\n\n".format(out))


    if not os.path.isdir(name):
        os.mkdir(name)

    with open("{}/esmFldsExchange.F90".format(name), "w") as fh:
        fh.write(out)
    
    
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 gen.py <input.yaml>\n")
    else:
        gen(sys.argv[1])
        
