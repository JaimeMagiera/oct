#!/usr/bin/env python
import requests
import click
import subprocess

@click.command()
@click.option('--version', default='', help='The OKD minor version to query') 
@click.option('--select/--no-select', default=False, help='Used in conjunction with the version flag, allows you to select a particular accepted release and extract the respective tools.')
@click.option('--auto/--no-auto', default=False, help='Optional flag to automatically download the respective tools for the latest available accepted release')
@click.option('--debug/--no-debug', default=False, help='Enable debug')
@click.option('--test/--no-test', default=False, help='Go through the motions, but not actually extract the materials.')
def decision_tree(version, select, auto, debug, test):
    if version:
        query_releases(version, select, auto, debug, test)
    else:
        query_releases("4.17", select, auto, debug, test)
        query_releases("4.16", select, auto, debug, test)
def list_releases(releases):
    for release in releases:
        print(release.decode())

def select_release(releases, test):
    index=0
    print("Available Releases:")
    for release in releases:
        print("%s: %s" % (index, release.decode()))
        index+=1
    selection = input('Please enter your selection: ')    
    selected_release=releases[int(selection)]
    print(selected_release.decode())
    if not test:
        extract_tools(selected_release)
    else:
        print("Test complete.")
        exit(0)

def extract_tools(selected_release): 
    #if debug:
    #    print("extract_tools()")
    print("Downloading and extracting the tools...")
    registry_url = f"registry.ci.openshift.org/origin/release-scos:%s" % (selected_release.decode())
    oc_cmd = subprocess.Popen(["oc", "adm", "release", "extract", "--tools", registry_url], stdout=subprocess.PIPE)
    stdout, stderr = oc_cmd.communicate()
    print("Done.")

def query_releases(version, select, auto, debug, test):
    release_name = f"{version}.0-0.okd-scos"
    query_url = f"https://amd64.origin.releases.ci.openshift.org/releasestream/{release_name}"
    response = requests.get(query_url)
    if response.status_code == 200:
        echo_cmd = subprocess.Popen(["echo", response.text], stdout=subprocess.PIPE)
        grep_cmd = subprocess.Popen(["grep", "Accepted", "-B 1"], stdin=echo_cmd.stdout, stdout=subprocess.PIPE)
        awk_cmd = subprocess.Popen(['awk', 'sub(/.*release\/ */,""){f=1} f{if ( sub(/ *".*/,"") ) f=0; print}'], stdin=grep_cmd.stdout, stdout=subprocess.PIPE)
        xargs_cmd = subprocess.Popen(['xargs'], stdin=awk_cmd.stdout, stdout=subprocess.PIPE)
        stdout, stderr = xargs_cmd.communicate()
        accepted_releases=stdout.split()
        if not accepted_releases:
            print(f"No accepted releases for {release_name} available.")
            exit(0)
        else:
            if auto:
                selected_release=accepted_releases[0]
                print(f"Auto selecting %s for download and extraction..." % selected_release.decode())
                if not test:
                    extract_tools(selected_release)
                else:
                    print("Test complete.")
                    exit(0)
            else:
                if select: 
                    select_release(accepted_releases, test)
                else:
                    list_releases(accepted_releases)
    else:
        print(f"Could not retrieve html.\nError: {response.status_code}")

if __name__ == '__main__':
    decision_tree()
