#!/usr/local/bin/python3

import itertools
import re
import sys
import xml.etree.cElementTree as ET

IPSEC_CONF = '/usr/local/etc/ipsec.conf'
PFSENSE_CONF = '/conf/config.xml'
rtt_time_warn = 200
rtt_time_error = 300

#Parse the XML
tree = ET.parse(PFSENSE_CONF)
root = tree.getroot()

#Function to find phase description by ikeid
def findDescr(ikeid):

    search = "./ipsec/phase1/[ikeid='" + ikeid + "']."


    for tunnel in root.findall(search):
        descr = tunnel.find('descr').text

        return descr

    return "Not found"

#Function to set correct format on ikeId. Recives conIDXXX, return ID
def formatIkeId(ikeid):

    #Convert list  into a string

    ikeid = ikeid[0]

    #If ikeid has 8 or more positions, get the position 3 and 4
    if len(ikeid) >= 8:
        ikeid = ikeid[3] + ikeid[4]
    else:
        #Else, get only the position 3. That is because some ikeids are small
        ikeid = ikeid[3]

    return ikeid

def parseConf():
    reg_conn = re.compile('^conn\s((?!%default).*)')
    reg_left = re.compile('.*leftid =(.*).*')
    reg_right = re.compile('.*rightid =(.*).*')
    data = {}

    with open(IPSEC_CONF, 'r') as f:
        for key, group in itertools.groupby(f, lambda line: line.startswith('\n')):
            if not key:
                conn_info = list(group)
                conn_tmp = [m.group(1) for l in conn_info for m in [reg_conn.search(l)] if m]
                left_tmp = [m.group(1) for l in conn_info for m in [reg_left.search(l)] if m]
                right_tmp = [m.group(1) for l in conn_info for m in [reg_right.search(l)] if m]
                if len(conn_tmp) > 0 :
                    descr = findDescr(formatIkeId(conn_tmp))
                else:
                    descr = "Not found"
                if conn_tmp and left_tmp and right_tmp:
                    data[conn_tmp[0]] = [left_tmp[0], right_tmp[0], descr]
    return data

def getTemplate():
    template = """
        {{ "{{#TUNNEL}}":"{0}","{{#TARGETIP}}":"{1}","{{#SOURCEIP}}":"{2}","{{#DESCRIPTION}}":"{3}" }}"""

    return template

def getPayload():
    final_conf = """{{
    "data":[{0}
    ]
}}"""

    conf = ''
    data = parseConf().items()
    for key,value in data:
        tmp_conf = getTemplate().format(
            key,
            value[1],
            value[0],
            value[2],
            rtt_time_warn,
            rtt_time_error
        )
        if len(data) > 1:
            conf += '%s,' % (tmp_conf)
        else:
            conf = tmp_conf
    if conf[-1] == ',':
        conf=conf[:-1]
    return final_conf.format(conf)

if __name__ == "__main__":
    ret = getPayload()
    sys.exit(ret)
