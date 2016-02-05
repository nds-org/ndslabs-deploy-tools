import locale
from dialog import Dialog
import argparse
import time
import os
import sys
import requests
from string import Template
import novaclient
from novaclient import client as nvclient
from heatclient import client as htclient
from keystoneclient import client as ksclient
from keystoneclient import session as kssession
from keystoneclient.auth.identity import v2 as auth
from heatclient.shell import HeatShell
import contextlib

locale.setlocale(locale.LC_ALL, '')

def get_keystone_creds():
    d = {}
    d['username'] = os.environ['OS_USERNAME']
    d['password'] = os.environ['OS_PASSWORD']
    d['auth_url'] = os.environ['OS_AUTH_URL']
    d['tenant_name'] = os.environ['OS_TENANT_NAME']
    return d

def get_nova_creds():
    d = {}
    d['username'] = os.environ['OS_USERNAME']
    d['api_key'] = os.environ['OS_PASSWORD']
    d['auth_url'] = os.environ['OS_AUTH_URL']
    d['project_id'] = os.environ['OS_TENANT_NAME']
    return d


d = Dialog(dialog="dialog", autowidgetsize=True)
d.set_background_title("NDSLabs OpenStack Deploy Assitant")

class NoGood(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

def error(msg):
    d.msgbox("ERROR: "+msg)
    sys.exit(1)

def debug(msgs):
    # return
    print msgs
    #info(msgs)


def info(msg):
    if d:
        ret = d.msgbox(msg)
        if ret != d.DIALOG_OK:
            debug("Cancelled by user")
            sys.exit(1)
    else: 
        print(msg)


#
# Select, if there is a NEWFUNC function, then there is a "create one"
#
def select(choices,msg,NEWFUNC=None):
    i = 0;
    chlist = [];
    for k in choices:
        i=i+1;
        chlist.append((str(i), k));
    if NEWFUNC:
        chlist.append(('NEW', "Create One"));
    try:
        code, tag = d.menu(msg, choices=chlist);
        if (code != d.DIALOG_OK):
          print("Exit by user choice");
          sys.exit(1)
        if (tag == 'NEW'):
            return NEWFUNC()
    except:
        print "No dialog, input choice:"
        print chlist
        tag = input()
    # Selection good, not new
    choice = chlist[int(tag)-1][1]
    debug ("Chose "+choice)
    return choice


def newkey():
    debug ('newkey')
    code, name = d.inputbox("Enter New KeyPair Name")
    if (code != d.DIALOG_OK):
        error("New Key cancelled")
    newkey = nova.keypairs.create(name)
    pubkey = newkey.public_key
    msg = "Public key:\n\n" + pubkey
    info(msg)
    print newkey
    return  name

def deploy():
    info("\nNDS Openstack Cluster Deployment Assistant:\n\n   latest instructions at:\n   http://labsportal.nationaldataservice.org/nds-labs-quick-start-guide/\n\nOK/ENTER to begin, ESC exits\n") 
    #
    # Failfast if can't connect
    #
    if not get_nova_creds():
        info("Container is misconfigured, see instructions or run with usage command")
        sys.exit(1)
    #
    # Connect to nova, heat
    #
    try:
        nova = nvclient.Client("2", **get_nova_creds())
        ksauth = auth.Password(**get_keystone_creds())
        kssess = kssession.Session(ksauth)
        kstok = kssess.get_token()
        heatLoc = ksauth.get_endpoint(kssess,service_type='orchestration')
        heat = htclient.Client("1", endpoint=heatLoc, token=kstok)
    except:
        message("Can't connect to heat API")
        sys.exit(1)
        
    try:
        keys = nova.keypairs;
        networks = nova.networks;
        flavors = nova.flavors;
        images = nova.images;
        secgroup = nova.security_groups;
        keylist = []
        for k in keys.list():
            keylist.append(k.to_dict()['keypair']['name'])
        netlist = []
        for k in networks.list():
            netlist.append(k.to_dict()['label'])
        flavlist = []
        for k in flavors.list():
            flavlist.append(k.to_dict()['name'])
        imglist = []
        for k in images.list():
            imglist.append(k.to_dict()['name'])
        seclist = []
        for k in secgroup.list():
            seclist.append(k.to_dict()['name'])
            secgroup.list()
    except:
        info("Error: could not read OpenStack keypairs, networks, flavors, images, securitygroups, can't continue")
        sys.exit(1)
    #
    keysel = select(keylist,"Select the KeyPair to Use",NEWFUNC=newkey)
    flavsel = select(flavlist,"Select the Flavor To Use")
    imgsel = select(imglist,"Select the Image to Use")
    netsel = select(netlist,"Select the private Network")
    secsel = select(seclist,"Select the Security Group to use")
    debug  ("selections : "+ " "+keysel+ " "+flavsel+ " "+imgsel+ " "+netsel+ " "+secsel)
    #
    # deploy, use the heat shell and capture the output
    #
    code, stackname = d.inputbox("Name for this cluster:");
    # TODO create dialog
    if (code != d.DIALOG_OK):
        fail("Exit by user choice")
    finalmsg = "Ready to deploy cluster:  \n" + "\n\tStack Name: "+ stackname + "\n\tImage: "+imgsel+ "\n\tFlavor: "+flavsel+ "\n\tKeyPair: "+keysel+ "\n\tNetwork: "+netsel+ "\n\tSecurityGroup: "+secsel+ "\n\n\n\t\t OK/Enter to deploy, ESC/^C to cancel/exit\n\n" 
    info(finalmsg)
    # 
    args = []
    args.append('stack-create')
    args.append('-f')
    args.append('/usr/local/lib/nds/templates/corekube-openstack.yaml')
    args.append('-Pcoreos_image='+imgsel)
    args.append('-Pflavor='+flavsel)
    args.append('-Pkeyname='+keysel)
    args.append('-Pprivate-network-id='+netsel)
    #args.append('-Psecuritygroup='+secsel)
    args.append(stackname)
    HeatShell().main(args)
#
# ETCD Token, won't work in private firewalled clouds
#
    etcd_token = requests.get("https://discovery.etcd.io/new").text
            

#
# Redirects stdio and stderr in with capture() as out: ...
#
def capture():
    import sys
    from cStringIO import StringIO
    oldout,olderr = sys.stdout, sys.stderr
    try:
        out=[StringIO(), StringIO()]
        sys.stdout,sys.stderr = out
        yield out
    finally:
        sys.stdout,sys.stderr = oldout, olderr
        out[0] = out[0].getvalue()
        out[1] = out[1].getvalue()

#@contextlib.contextmanager
if __name__ == "__main__":
    #with capture() as out:
    deploy()
    #info(out)

