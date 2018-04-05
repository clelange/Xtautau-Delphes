# Xtautau-Delphes

# Initial setup

Currently based on `CMSSW_9_3_0_pre3`, but this is arbitrary.

```
git clone git@github.com:clelange/Xtautau-Delphes.git
cd Xtautau-Delphes
cmsrel CMSSW_9_3_0_pre3
```

Furthermore, install `LHAPDF`, `FastJet`, and `Delphes`.

There are a couple of hard-coded path names, e.g. `/afs/cern.ch/work/c/clange/SVFit/`, which needs to be adjusted to your `Xtautau-Delphes` working directory.

# Everytime setup

```
source setup.sh
```

# Batch submission

## H->tautau submission

In [`BatchSubmission/submitBatch.py`](../blob/master/BatchSubmission/submitBatch.py) define a list with mass points and for each of them create a dictionary entry in `job_indices` to define how many jobs to run. Also set whether you want to run with our without skimming by setting the corresponding shell script `command` in the `main()`` function. In [`BatchSubmission/submitBatch.sh`](../blob/master/BatchSubmission/runBatch.sh) or [`BatchSubmission/runBatch_noSkim.sh`](../blob/master/BatchSubmission/runBatch_noSkim.sh) set the `STAGEOUTBASE` as output directory (and create it if needed). Then execute:

```
python BatchSubmission/submitBatch.py
```

## Z->tautau submission

Same procedure as for H->tautau, just use the files with the `_Z` suffix.

```
python BatchSubmission/submitBatch_Z.py
```
