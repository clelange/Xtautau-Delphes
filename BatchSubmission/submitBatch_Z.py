#!/usr/bin/env python
#
# Creating dir:
#   uberftp t3se01.psi.ch 'mkdir /pnfs/psi.ch/cms/trivcat/store/user/ineuteli/samples/LowMassDiTau_madgraph'
#

import os
import sys
# import subprocess
# import time

WORKPATH = "/afs/cern.ch/work/c/clange/SVFit/"
CARDDIR = WORKPATH + "Cards/"
PARAMCARD = "param_card.dat"
# masses = range(55, 301, 5)
# masses = range(5, 301, 5)
masses = [91.188]
job_indices = {}
for mass in masses:
    # job_indices[mass] = range(int(15000/mass))
    # job_indices[mass] = range(50)
    job_indices[mass] = range(1,251)
# job_indices[100] = [5, 12]


def createParamCard(mass):
    stringToFind = "23 9.118800e+01 # MZ"
    newString = "   23 %E # MZ \n" % mass
    newParamCard = "%sZ_%s_%s" % (CARDDIR, mass, PARAMCARD)
    with open(CARDDIR+PARAMCARD, 'r') as inFile:
        with open(newParamCard, 'w') as outFile:
            lines = inFile.readlines()
            for i, line in enumerate(lines):
                if line.find(stringToFind) >= 0:
                    lines[i] = newString
                    break
            outFile.writelines(lines)


def main():
    print "Starting batch submission"

    # ensure directory
    REPORTDIR = "%s/logs" % (WORKPATH)
    if not os.path.exists(REPORTDIR):
        os.makedirs(REPORTDIR)
        print ">>> created directory " + REPORTDIR

    for sample in masses:
        createParamCard(sample)
        for index in job_indices[sample]:
            jobname = "%s_%d" % (sample, index)
            # command = "qsub -q all.q -N %s submitMG.sh %s %s" % (jobname, sample, index)
            command = "bsub -q 8nh -N -J %s runBatch_Z.sh %s %s" % (jobname, sample, index)
            print "\n>>> " + command.replace(jobname, "\033[;1m%s\033[0;0m" % jobname, 1)
            sys.stdout.write(">>> ")
            sys.stdout.flush()
            os.system(command)

    print ">>>\n>>> done\n"


if __name__ == '__main__':
    main()
