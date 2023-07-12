import yaml, sys

filename = sys.argv[1];
url_prefix = sys.argv[2];

with open(filename, "r") as stream:
    try:
        data = yaml.safe_load(stream)
        for key, value in data["paths"].items():
            if url_prefix is not None:
                print(str(value["get"]["summary"]) +":" + url_prefix + str(key))     
            else:
                print(str(key))        
    except yaml.YAMLError as exc:
        print(exc)