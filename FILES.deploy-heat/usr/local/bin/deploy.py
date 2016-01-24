import locale
from dialog import Dialog
import argparse
import time
import os
import sys
import requests
from string import Template
from novaclient import client as nvclient
import novaclient

locale.setlocale(locale.LC_ALL, '')
CONF = {'keyname': "NDS'', "}

def get_openstack_creds():
    d = {}
    d['username'] = os.environ['OS_USERNAME']
    d['password'] = os.environ['OS_PASSWORD']
    d['auth_url'] = os.environ['OS_AUTH_URL']
    d['tenant_name'] = os.environ['OS_TENANT_NAME']
    return d

def fail(text):
    print ("Can't Continue: ", text)
    sys.exit(1);

if __name__ == "__main__":
    def error(msg):
        d.msgbox("ERROR: "+msg, width=60, height=20)
        sys.exit(1)

    d = Dialog(dialog="dialog")
    d.set_background_title("NDSLabs OpenStack Deploy Assitant")
    if d.msgbox("NDS Openstack Deploy Assistant\n\nThis assistant will help you choose OpenStack parameters from your environment to provision and start a NDSLabs cluster", width=60, height=10) != d.DIALOG_OK:
        fail()
    try:
        creds = get_openstack_creds()
        creds = get_nova_creds()
        nova = nvclient.Client(**creds)
    except:
        error("Unable to connect to OpenStack")
    try:
        keymanager = nova.keypairs;
        networks = nova.networks;
        flavors = nova.flavors;
        images = nova.images;
        secgroup = nova.secgroup;

#
# KeyPairs
#
        keymanager.list()
        keys = keyManager.list()
        if (len(keys) == 0):
          if (d.yesno("Didn't find any keypairs") != d.DIALOG_OK):
            fail("Exit by request")
        i = 0;
        choices = [];
        for k in keys:
            i=i+1;
            kn =  k.to_dict()
            choices.append(("i", kn['keypair']['name']));
        choices.append(("i", "Create New KeyPair"));
        
        code, tag = d.menu(choices);
        if (code != d.DIALOG_OK):
          fail("Exit by user choice");
        if (tag == "i"):
          code, tag = d.inputbox("Enter the name for a new KeyPair");
        if (code != d.DIALOG_OK):
          fail("Exit by user choice")
        keypair = tag;
#
# ETCD Token, won't work in private firewalled clouds
#
        etcd_token = requests.get("https://discovery.etcd.io/new").text
                

    except:
        error("Unable to read all OpenStack Information")

