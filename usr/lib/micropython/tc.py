import os

def readtczlist(filename):
    fp = open(filename)
    tcz = []

    while True:
        ln = fp.readline()

        if ln == '':
            break

        s = ln.strip()

        if len(s) <= 4:
            continue

        if s[0] == '#' or s[0] == ';':
            continue

        if s[-4:] != '.tcz':
            continue

        try:
            tcz.index(s)
        except ValueError:                        
            tcz.append(s.replace('KERNEL', kernel))

    fp.close()

    return tcz


# Get kernel version

fp = open('/proc/sys/kernel/osrelease', 'rt')
kernel = fp.readline().strip()
fp.close()

# Get number of cpu's

cpunr = 0

for p in  os.listdir('/proc/device-tree/cpus'):
    if p[:4] == 'cpu@':
        cpunr += 1

if cpunr == 0:
    cpunr = 1
    
# Get cmdline args

fp = open('/proc/cmdline', 'rt')
cmdline = fp.readline().split()
fp.close()
