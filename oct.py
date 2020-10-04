#!/bin/python
# version 0.1
import os
import sys
import argparse
import socket
import subprocess
import time
import requests
from urllib.parse import urlparse
import urllib.request
from pathlib import Path
import tarfile

okd_installer_url = "https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-10-03-012432/openshift-install-linux-4.5.0-0.okd-2020-10-03-012432.tar.gz"

okd_client_url = "https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-10-03-012432/openshift-client-linux-4.5.0-0.okd-2020-10-03-012432.tar.gz"

fcos_image_url = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20200907.3.0/x86_64/fedora-coreos-32.20200907.3.0-vmware.x86_64.ova"

print ('OKD Cluster Tool');

parser = argparse.ArgumentParser(description='Process the input.')
parser.add_argument('-dio', '--download-image', required=False, nargs='?', action='store', dest='download-image', help='Download the latest OS image')
parser.add_argument('-dc', '--download-client', required=False, nargs='?', action='store', dest='download-client', help='Download the latest oc command line application')
parser.add_argument('-di', '--download-installer', required=False, nargs='?', action='store', dest='download-installer', help='Download the latest installer')
parser.add_argument('-p', '--prepare-environment', required=False, nargs='?', action='store', dest='prepare-environment', help='Prepare an installation environment')

arg_results = parser.parse_args()
dict_results = vars(arg_results)

##print(dict_results);

def downloadImage(imageType):
    if(imageType == 'fcos'):
        print("Downloading " + fcos_image_url + "...");
        output = urlparse(fcos_image_url)
        urllib.request.urlretrieve(fcos_image_url, os.path.basename(os.path.normpath(output.path)))
    elif(imageType == 'rcos') : 
        print("Downloading " + imageType  + " image...");
    else:
        print('Unrecognized image type')


def downloadClient(clientType):
    if(clientType == 'okd'):
        print("Downloading " + okd_client_url + "...");
        output = urlparse(okd_client_url)
        urllib.request.urlretrieve(okd_client_url, "oc.tar.gz")
    elif(clientType == 'rcos') :
        print("Downloading " + imageType  + " client...");
    else:
        print('Unrecognized client type')

def downloadInstaller(installerType):
    if(installerType == 'okd'):
        print("Downloading " + okd_installer_url + "...");
        output = urlparse(okd_installer_url)
        urllib.request.urlretrieve(okd_installer_url, "openshift-install-linux.tar.gz")
    elif(installerType == 'openshift'):
        print("Downloading " + installerType  + " installer...");
    else:
        print('Unrecognized installer type')
        
def prepareEnvironment(environmentType):
    print("Preparing installation environment for " + environmentType);
    binPath = os.path.join(os.getcwd(),"bin")
    print(binPath);
    if(os.path.exists(binPath) == False):
        os.mkdir(binPath)
    downloadInstaller(environmentType)
    t = tarfile.open("openshift-install-linux.tar.gz", 'r')
    t.extractall()
    os.rename("openshift-install", "bin/openshift-install")
    os.remove("openshift-install-linux.tar.gz")
    os.remove("README.md")
    downloadClient(environmentType)
    t = tarfile.open("oc.tar.gz")
    t.extractall()
    os.rename("oc", "bin/oc")
    os.rename("kubectl", "bin/kubectl")
    os.remove("oc.tar.gz")
    os.remove("README.md")

    if(environmentType == 'okd'):
        downloadImage("fcos") 

if dict_results["download-image"]:
    print("download-image called")
    downloadImage(dict_results["download-image"])

if dict_results["download-client"]:
    print("download-client called")
    downloadClient(dict_results["download-client"])

if dict_results["download-installer"]:
     print("download-installer called")
     downloadInstaller(dict_results["download-installer"])

if dict_results["prepare-environment"]:
    print("prepare-environment called")
    prepareEnvironment(dict_results["prepare-environment"])    
