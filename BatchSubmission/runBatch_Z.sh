#! /bin/bash

printf "###########################################\n"
printf "##   Run Delphes for samples %-12s##\n" "$1"
printf "###########################################\n"


MASS="$1"
N="$2"
MASSN="${MASS}_${N}"
FINALOUTFILES="*.root"

DBG=2
JOBLOGFILES="myout.txt myerr.txt"
BASEDIR="/afs/cern.ch/work/c/clange/SVFit/"
MG5DIR="${BASEDIR}/MG5_aMC_v2_5_5"

WORKDIR=${TMPDIR}
STAGEOUTBASE=/eos/cms/store/cmst3/group/exovv/clange/Ztautau_skim
STAGEOUTDIR="${STAGEOUTBASE}/$MASS/$N"
LOGOUTDIR="${BASEDIR}/logs/"
SELECTIONSCRIPT="${BASEDIR}/Scripts/eventSelect.py"

CARDDIR="$BASEDIR/Cards"
CARDS="run pythia8 delphes options" # run_card is copied by hand below
PROCESS="Ztautau"
OUTDIR=$WORKDIR/${PROCESS}/Events/${MASSN}

##### MONITORING/DEBUG INFORMATION ########################################

mkdir -p ${BASEDIR}/logs

DATE_START=`date +%s`
echo "Job started at " `date`
cat <<EOF

###########################################
##       QUEUEING SYSTEM SETTINGS:       ##
###########################################
  HOME=$HOME
  USER=$USER
  JOB_ID=$JOB_ID
  JOB_NAME=$JOB_NAME
  HOSTNAME=$HOSTNAME
  TASK_ID=$TASK_ID
  QUEUE=$QUEUE
  TMPDIR=$TMPDIR
EOF

if test 0"$DBG" -gt 0; then
    echo " "
    echo "###########################################"
    echo "##         Environment Variables         ##"
    echo "###########################################"
    env
fi



##### SET ENVIRONMENT #####################################################

export BASEDIR=${BASEDIR}
cd ${BASEDIR} || exit
cd CMSSW_9_3_0_pre3/src || exit
eval `scramv1 runtime -sh`
cd ../.. || exit
export PATH=${BASEDIR}/lhapdf/bin:$PATH
export PATH=${BASEDIR}/fastjet/bin:$PATH
export LD_LIBRARY_PATH=${BASEDIR}/delphes:$LD_LIBRARY_PATH


cat <<EOF

###########################################
##             JOB SETTINGS:             ##
###########################################
  BASEDIR=$BASEDIR
  WORKDIR=$WORKDIR
  STAGEOUTDIR=$STAGEOUTDIR
EOF



echo " "
echo "###########################################"
echo "##         MY FUNCTIONALITY CODE         ##"
echo "###########################################"

cd ${WORKDIR} || exit
# source $VO_CMS_SW_DIR/cmsset_default.sh >&2

for logfile in $JOBLOGFILES; do
  touch $WORKDIR/$logfile
done

# make process dir
echo "\
$MG5DIR/bin/mg5_aMC $CARDDIR/proc_card_mg5_Z.dat 2>&1 >> myout.txt 2>> myerr.txt"
$MG5DIR/bin/mg5_aMC $CARDDIR/proc_card_mg5_Z.dat >> myout.txt 2>> myerr.txt

# copy cards
echo "\
mkdir -p $WORKDIR/${PROCESS}/Cards"
mkdir -p $WORKDIR/${PROCESS}/Cards
for CARD in $CARDS; do
  echo "cp $CARDDIR/${CARD}_card.dat $WORKDIR/${PROCESS}/Cards/${CARD}_card.dat"
  cp $CARDDIR/${CARD}_card.dat $WORKDIR/${PROCESS}/Cards/${CARD}_card.dat
done
# echo "cp $CARDDIR/run_card_Z.dat $WORKDIR/${PROCESS}/Cards/run_card.dat"
# cp $CARDDIR/run_card_Z.dat $WORKDIR/${PROCESS}/Cards/run_card.dat

# need to change random seed
sed -i "s/0   = iseed/${N}   = iseed/g" "$WORKDIR/${PROCESS}/Cards/run_card.dat"
cat "$WORKDIR/${PROCESS}/Cards/run_card.dat"

echo "cp $CARDDIR/Z_${MASS}_param_card.dat $WORKDIR/${PROCESS}/Cards/param_card.dat"
cp $CARDDIR/Z_${MASS}_param_card.dat $WORKDIR/${PROCESS}/Cards/param_card.dat

echo "ls"
ls

# generate events
echo "\
${WORKDIR}/${PROCESS}/bin/generate_events ${MASSN} < $WORKDIR/${PROCESS}/Cards/options_card.dat >> myout.txt 2>> myerr.txt"
${WORKDIR}/${PROCESS}/bin/generate_events ${MASSN} < $WORKDIR/${PROCESS}/Cards/options_card.dat >> myout.txt 2>> myerr.txt

echo "ls"
ls

##### RETRIEVAL OF OUTPUT FILES AND CLEANING UP ###########################
echo "mkdir -p $STAGEOUTDIR"
mkdir -p $STAGEOUTDIR

cd $WORKDIR || exit
if test 0"$DBG" -gt 0; then
    echo " "
    echo "###########################################################"
    echo "##   MY OUTPUT WILL BE MOVED TO \$STAGEOUTDIR and \$LOGOUTDIR   ##"
    echo "###########################################################"
    echo "  \$STAGEOUTDIR=$STAGEOUTDIR"
    echo "  \$LOGOUTDIR=$LOGOUTDIR"
    echo "  Working directory contents:"
    echo "  pwd: " `pwd`
    find -maxdepth 3 -ls #ls -Rl
    ls $STAGEOUTDIR
fi

REPORTDIR=${LOGOUTDIR}/Z_${MASS}

cd $OUTDIR || exit
cp $SELECTIONSCRIPT .
SCRIPTNAME=`basename $SELECTIONSCRIPT`
for j in `ls $FINALOUTFILES`; do
    NEWOUTFILE=skim_`basename $j`
    # echo ">>> running root -x -b \'$SCRIPTNAME (\"$j\",\"$NEWOUTFILE\")\'"
    # root -x -b "$SCRIPTNAME (\"$j\",\"$NEWOUTFILE\")" >&2
    echo ">>> running python $SCRIPTNAME $j $NEWOUTFILE"
    python $SCRIPTNAME $j $NEWOUTFILE >&2
    rm $j
done

cd $WORKDIR || exit
if test x"$REPORTDIR" != x; then
    mkdir -p ${REPORTDIR}
    if test ! -e "$REPORTDIR"; then
        echo "ERROR: Failed to create $REPORTDIR ...Aborting..." >&2
        exit 1
    fi
    for n in $JOBLOGFILES; do
        echo ">>> copying $n"
        if test ! -e $WORKDIR/$n; then
            echo "WARNING: Cannot find output file $WORKDIR/$n. Ignoring it" >&2
        else
            cp -a $WORKDIR/$n $REPORTDIR/${MASS}_$N_$n
            if test $? -ne 0; then
                echo "ERROR: Failed to copy $WORKDIR/$n to $REPORTDIR/${MASS}_$N_$n" >&2
            fi
    fi
    done
fi

cd $OUTDIR || exit
for j in `ls $FINALOUTFILES`; do
    echo ">>> copying $OUTDIR/$j to $STAGEOUTDIR/$j"
    cp -a $OUTDIR/$j $STAGEOUTDIR/$j >&2
done


# echo "Cleaning up $WORKDIR"
# rm -rf $WORKDIR



###########################################################################

DATE_END=`date +%s`
RUNTIME=$((DATE_END-DATE_START))
echo " "
echo "#####################################################"
echo "    Job finished at " `date`
echo "    Wallclock running time: $(( $RUNTIME / 3600 )):$(( $RUNTIME % 3600 /60 )):$(( $RUNTIME % 60 )) "
echo "#####################################################"
echo " "

exit 0
