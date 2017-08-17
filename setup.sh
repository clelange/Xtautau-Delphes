export BASEDIR=/afs/cern.ch/work/c/clange/SVFit
cd CMSSW_9_3_0_pre3/src
eval `scramv1 runtime -sh`
cd ../..
export PATH=${BASEDIR}/lhapdf/bin:$PATH
export PATH=${BASEDIR}/fastjet/bin:$PATH
export LD_LIBRARY_PATH=${BASEDIR}/delphes:$LD_LIBRARY_PATH
