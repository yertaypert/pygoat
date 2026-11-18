import json, collections

def trivy(path):
    d = json.load(open(path))
    v = [x for r in d["Results"] if r["Target"] == "requirements.txt"
         for x in r.get("Vulnerabilities", [])]
    return len(v), dict(collections.Counter(x["Severity"] for x in v))

def bandit(path, main_only=False):
    r = json.load(open(path))["results"]
    if main_only:
        r = [x for x in r if not x["filename"].lstrip("./").startswith(("dockerized_labs", "challenge/labs"))]
    return len(r), dict(collections.Counter(x["issue_severity"] for x in r))

def semgrep(path, main_only=False):
    res = [x for run in json.load(open(path))["runs"] for x in run["results"]]
    if main_only:
        res = [x for x in res
               if not x["locations"][0]["physicalLocation"]["artifactLocation"]["uri"].lstrip("./")
               .startswith(("dockerized_labs", "challenge/labs"))]
    return len(res)

for stage in ("before", "after"):
    p = f"evidence/{stage}/"
    print(f"== {stage} ==")
    print("trivy (root requirements.txt):", trivy(p + "trivy-sca.json"))
    print("bandit all / main app:", bandit(p + "bandit.json"), bandit(p + "bandit.json", True))
    print("semgrep all / main app:", semgrep(p + "semgrep.sarif"), semgrep(p + "semgrep.sarif", True))
